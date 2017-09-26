#!/bin/bash -x

EXTERNAL_IP=$(curl -s -m 10 http://whatismyip.akamai.com/)
NAMESPACE=$(echo -n "${domain_name}" | sed "s/\.oraclevcn\.com//g")
FQDN_HOSTNAME=$(getent hosts $(ip route get 1 | awk '{print $NF;exit}') | awk '{print $2}')

# make sure ubuntu owns home dir
chown ubuntu:ubuntu /home/ubuntu

## create policy file that blocks autostart of services on install
printf '#!/bin/sh\necho "All runlevel operations denied by policy" >&2\nexit 101\n' >/tmp/policy-rc.d && chmod +x /tmp/policy-rc.d
ETCD_LB=${etcd_lb}
export HOSTNAME=$(hostname)

export IP_LOCAL=$(ip route show to 0.0.0.0/0 | awk '{ print $5 }' | xargs ip addr show | grep -Po 'inet \K[\d.]+')

SUBNET=$(getent hosts $IP_LOCAL | awk '{print $2}' | cut -d. -f2)

until apt-get update; do sleep 1 && echo -n "."; done

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
envsubst </home/ubuntu/services/flannel.service >/etc/systemd/system/flannel.service
systemctl daemon-reload && systemctl enable flannel && systemctl start flannel

## INSTALL CNI PLUGIN
######################################
mkdir -p /opt/cni/bin /etc/cni/net.d
curl -L --retry 3 https://github.com/containernetworking/cni/releases/download/v0.5.2/cni-amd64-v0.5.2.tgz -o /tmp/cni-plugin.tar.gz
tar zxf /tmp/cni-plugin.tar.gz -C /opt/cni/bin/
printf '{\n    "name": "podnet",\n    "type": "flannel",\n    "delegate": {\n        "isDefaultGateway": true\n    }\n}\n' >/etc/cni/net.d/10-flannel.conf
cp /home/ubuntu/services/cni-bridge.service /etc/systemd/system/cni-bridge.service
cp /home/ubuntu/services/cni-bridge.sh /usr/local/bin/cni-bridge.sh && chmod +x /usr/local/bin/cni-bridge.sh
systemctl enable cni-bridge && systemctl start cni-bridge

# Install Docker prereqs
apt-get install -y aufs-tools cgroupfs-mount libltdl7

# Download Docker
curl -L --retry 3 https://download.docker.com/linux/ubuntu/dists/xenial/pool/stable/amd64/${docker_ver}.deb -o /tmp/${docker_ver}.deb

# Disable debian autostart of service
cp /tmp/policy-rc.d /usr/sbin/policy-rc.d

# Install Docker
until dpkg -i /tmp/${docker_ver}.deb; do sleep 1 && echo -n "."; done
systemctl stop docker.service
rm -f /lib/systemd/system/docker.service && cat /home/ubuntu/services/docker.service >/lib/systemd/system/docker.service
systemctl daemon-reload && systemctl restart docker

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

# Update packages
apt-get install -y apt-transport-https
curl -s --retry 3 https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo 'deb http://apt.kubernetes.io/ kubernetes-xenial main' >/etc/apt/sources.list.d/kubernetes.list
apt-get update

# install kubelet
apt-get install -y kubelet=${k8s_ver}-00 kubectl

# Pull etcd docker image from registry
docker pull quay.io/coreos/etcd:${etcd_ver}

# Start etcd proxy container
docker run -d \
	-p 2380:2380 -p 2379:2379 \
	-v /etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt \
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
sed -e "s/__FQDN_HOSTNAME__/$FQDN_HOSTNAME/g" /home/ubuntu/services/kubelet.service >/etc/systemd/system/kubelet.service
systemctl daemon-reload
systemctl start kubelet

until kubectl get all; do sleep 1 && echo -n "."; done

## wait for k8smaster to be healthy. possible race on pod networks otherwise
until [ "$(curl localhost:8080/healthz 2>/dev/null)" == "ok" ]; do
	sleep 3
done

kubectl create -f /etc/kubernetes/manifests/kube-dns.yaml

## install kubernetes-dashboard
kubectl create -f /etc/kubernetes/manifests/kubernetes-dashboard.yaml

echo "Finished running setup.sh"
