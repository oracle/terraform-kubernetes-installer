#!/bin/bash -x

EXTERNAL_IP=$(curl -s -m 10 http://whatismyip.akamai.com/)
NAMESPACE=$(echo -n "${domain_name}" | sed "s/\.oraclevcn\.com//g")
FQDN_HOSTNAME=$(getent hosts $(ip route get 1 | awk '{print $NF;exit}') | awk '{print $2}')

ETCD_LB=${etcd_lb}
export HOSTNAME=$(hostname)

export IP_LOCAL=$(ip route show to 0.0.0.0/0 | awk '{ print $5 }' | xargs ip addr show | grep -Po 'inet \K[\d.]+')

SUBNET=$(getent hosts $IP_LOCAL | awk '{print $2}' | cut -d. -f2)

## download etcdctl client
######################################
curl -L --retry 3 https://github.com/coreos/etcd/releases/download/${etcd_ver}/etcd-${etcd_ver}-linux-amd64.tar.gz -o /tmp/etcd-${etcd_ver}-linux-amd64.tar.gz
tar zxf /tmp/etcd-${etcd_ver}-linux-amd64.tar.gz -C /tmp/ && cp /tmp/etcd-${etcd_ver}-linux-amd64/etcd* /usr/local/bin/

# wait for etcd to become active (through the LB)
until [ $(/usr/local/bin/etcdctl --endpoints ${etcd_lb} cluster-health | grep '^cluster ' | grep -c 'is healthy$') == "1" ]; do
	echo "Waiting for cluster to be healthy"
	sleep 1
done

## Flannel
######################################
curl -L --retry 3 https://github.com/coreos/flannel/releases/download/${flannel_ver}/flanneld-amd64 -o /usr/local/bin/flanneld \
	&& chmod 755 /usr/local/bin/flanneld
export ETCD_SERVER=${etcd_lb}
echo "IP_LOCAL: $IP_LOCAL ETCD_SERVER: $ETCD_SERVER"
envsubst </root/services/flannel.service >/etc/systemd/system/flannel.service
systemctl daemon-reload && systemctl enable flannel && systemctl start flannel

## INSTALL CNI PLUGIN
######################################
mkdir -p /opt/cni/bin /etc/cni/net.d
curl -L --retry 3 https://github.com/containernetworking/cni/releases/download/v0.5.2/cni-amd64-v0.5.2.tgz -o /tmp/cni-plugin.tar.gz
tar zxf /tmp/cni-plugin.tar.gz -C /opt/cni/bin/
printf '{\n    "name": "podnet",\n    "type": "flannel",\n    "delegate": {\n        "isDefaultGateway": true\n    }\n}\n' >/etc/cni/net.d/10-flannel.conf

cp /root/services/cni-bridge.service /etc/systemd/system/cni-bridge.service
cp /root/services/cni-bridge.sh /usr/local/bin/cni-bridge.sh && chmod +x /usr/local/bin/cni-bridge.sh
systemctl enable cni-bridge && systemctl start cni-bridge

# Install Docker prereqs
until yum -y install aufs-tools cgroupfs-mount libltdl7 unzip; do sleep 1 && echo -n "."; done

# Stage master certs
unzip /tmp/k8s-certs.zip -d /etc/kubernetes/ssl/

# enable ol7 addons
yum-config-manager --disable ol7_UEKR3
yum-config-manager --enable ol7_addons ol7_latest ol7_UEKR4 ol7_optional ol7_optional_latest

# Install Docker
until yum -y install docker-engine-${docker_ver}; do sleep 1 && echo -n "."; done

systemctl stop docker

# Disable irqbalance for performance
service irqbalance stop
yum -y erase irqbalance

rm -f /lib/systemd/system/docker.service && cat /root/services/docker.service >/lib/systemd/system/docker.service
systemctl enable docker
systemctl daemon-reload
systemctl restart docker

# re-enable autostart
rm -f /usr/sbin/policy-rc.d

# Add default DNS
echo "nameserver 169.254.169.254" >>/etc/resolvconf/resolv.conf.d/base
resolvconf -u

# Output /etc/environment_params
echo "IPV4_PRIVATE_0=$IP_LOCAL" >>/etc/environment_params
echo "ETCD_IP=$ETCD_LB" >>/etc/environment_params
echo "FQDN_HOSTNAME=$FQDN_HOSTNAME" >>/etc/environment_params

# Drop firewall rules
iptables -F

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# Disable SELinux and firewall
setenforce 0
systemctl stop firewalld.service
systemctl disable firewalld.service

## Install kubelet, kubectl, and kubernetes-cni
###############################################
yum-config-manager --add-repo http://yum.kubernetes.io/repos/kubernetes-el7-x86_64
until yum install -y kubelet-${k8s_ver}-0 kubectl-${k8s_ver}-0; do sleep 1 && echo -n ".";done

# Pull etcd docker image from registry
docker pull quay.io/coreos/etcd:${etcd_ver}

# Start etcd proxy container
docker run -d \
	-p 2380:2380 -p 2379:2379 \
	-v /etc/ssl/certs/ca-bundle.crt:/etc/ssl/certs/ca-bundle.crt \
	--net=host \
	--restart=always \
	quay.io/coreos/etcd:${etcd_ver} \
	/usr/local/bin/etcd \
	-discovery ${etcd_discovery_url} \
	--proxy on

## Kubelet for the master
systemctl stop kubelet
rm /lib/systemd/system/kubelet.service
systemctl daemon-reload
sed -e "s/__FQDN_HOSTNAME__/$FQDN_HOSTNAME/g" /root/services/kubelet.service >/etc/systemd/system/kubelet.service
systemctl daemon-reload
systemctl enable kubelet
systemctl start kubelet

until kubectl get all; do sleep 1 && echo -n "."; done

## wait for k8smaster to be healthy. possible race on pod networks otherwise
until [ "$(curl localhost:8080/healthz 2>/dev/null)" == "ok" ]; do
	sleep 3
done

## install kube-dns
kubectl create -f /root/services/kube-dns.yaml

## install kubernetes-dashboard
kubectl create -f /root/services/kubernetes-dashboard.yaml

echo "Finished running setup.sh"
