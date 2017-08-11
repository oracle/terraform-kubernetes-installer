#!/bin/bash -x

EXTERNAL_IP=$(curl -s -m 10 http://whatismyip.akamai.com/)
NAMESPACE=$(echo -n "${domain_name}" | sed "s/\.oraclevcn\.com//g")
FQDN_HOSTNAME=$(getent hosts $(ip route get 1 | awk '{print $NF;exit}') | awk '{print $2}')

# pull instance metadata
curl -sL --retry 3 http://169.254.169.254/opc/v1/instance/ | tee /tmp/instance_meta.json

## create policy file that blocks autostart of services on install
printf '#!/bin/sh\necho "All runlevel operations denied by policy" >&2\nexit 101\n' >/tmp/policy-rc.d && chmod +x /tmp/policy-rc.d
export K8S_API_SERVER_LB=${master_lb}
export ETCD_LB=${etcd_lb}
export RANDFILE=$(mktemp)
export HOSTNAME=$(hostname)

export IP_LOCAL=$(ip route show to 0.0.0.0/0 | awk '{ print $5 }' | xargs ip addr show | grep -Po 'inet \K[\d.]+')

SUBNET=$(getent hosts $IP_LOCAL | awk '{print $2}' | cut -d. -f2)
export WORKER_IP=$IP_LOCAL

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

###################################### DOCKER ######################################

## Install Docker prereqs
######################################
until yum -y install aufs-tools cgroupfs-mount libltdl7 unzip; do sleep && echo -n "."; done

# Stage worker certs
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


## Add default DNS
######################################
echo "nameserver 169.254.169.254" >>/etc/resolvconf/resolv.conf.d/base
resolvconf -u

## Output /etc/environment_params
######################################
echo "IPV4_PRIVATE_0=$IP_LOCAL" >>/etc/environment_params
echo "ETCD_IP=$ETCD_LB" >>/etc/environment_params
echo "K8S_API_SERVER_LB=$K8S_API_SERVER_LB" >>/etc/environment_params
echo "FQDN_HOSTNAME=$FQDN_HOSTNAME" >>/etc/environment_params

## Drop firewall rules
######################################
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

until systemctl stop kubelet; do sleep 1; done
mkdir -p /opt/cni/bin /etc/cni/net.d
tar zxf /tmp/cni-plugin.tar.gz -C /opt/cni/bin/
printf '{\n    "name": "podnet",\n    "type": "flannel",\n    "delegate": {\n        "isDefaultGateway": true\n    }\n}\n' >/etc/cni/net.d/10-flannel.conf

###################################### ETCD ######################################

## Pull etcd docker image from registry
docker pull quay.io/coreos/etcd:${etcd_ver}

## Start etcd proxy container
######################################
docker run -d \
	-p 2380:2380 -p 2379:2379 \
	-v /etc/ssl/certs/ca-bundle.crt:/etc/ssl/certs/ca-bundle.crt \
	--net=host \
	--restart=always \
	quay.io/coreos/etcd:${etcd_ver} \
	/usr/local/bin/etcd \
	-discovery ${etcd_discovery_url} \
	--proxy on

## FQDN constructed from live environment since DNS label for the subnet is optional
sed -e "s/__FQDN_HOSTNAME__/$FQDN_HOSTNAME/g" /etc/kubernetes/manifests/kube-proxy.yaml >/tmp/kube-proxy.yaml
cat /tmp/kube-proxy.yaml >/etc/kubernetes/manifests/kube-proxy.yaml

## Kubelet for the worker
######################################
rm /lib/systemd/system/kubelet.service
systemctl daemon-reload

AVAILABILITY_DOMAIN=$(jq -r '.availabilityDomain' /tmp/instance_meta.json | sed 's/:/-/g')
read COMPARTMENT_ID_0 COMPARTMENT_ID_1 <<< $(jq -r '.compartmentId' /tmp/instance_meta.json | perl -pe 's/(.*?\.){4}\K/ /g' | perl -pe 's/\.+\s/ /g')
read NODE_ID_0 NODE_ID_1 <<< $(jq -r '.id' /tmp/instance_meta.json | perl -pe 's/(.*?\.){4}\K/ /g' | perl -pe 's/\.+\s/ /g')
NODE_SHAPE=$(jq -r '.shape' /tmp/instance_meta.json)

sed -e "s/__FQDN_HOSTNAME__/$FQDN_HOSTNAME/g" \
    -e "s/__EXT_IP__/$EXTERNAL_IP/g" \
    -e "s/__AVAILABILITY_DOMAIN__/$AVAILABILITY_DOMAIN/g" \
    -e "s/__COMPARTMENT_ID_PREFIX__/$COMPARTMENT_ID_0/g" \
    -e "s/__COMPARTMENT_ID_SUFFIX__/$COMPARTMENT_ID_1/g" \
    -e "s/__NODE_ID_PREFIX__/$NODE_ID_0/g" \
    -e "s/__NODE_ID_SUFFIX__/$NODE_ID_1/g" \
    -e "s/__NODE_SHAPE__/$NODE_SHAPE/g" \
    /root/services/kubelet.service > /etc/systemd/system/kubelet.service

## wait for k8smaster to be available. possible race on pod networks otherwise
until [ "$(curl -k --cert /etc/kubernetes/ssl/apiserver.pem --key /etc/kubernetes/ssl/apiserver-key.pem $K8S_API_SERVER_LB/healthz 2>/dev/null)" == "ok" ]; do
	sleep 3
done

sleep $[ ( $RANDOM % 10 )  + 1 ]s
systemctl daemon-reload
systemctl enable kubelet
systemctl start kubelet

######################################
echo "Finished running setup.sh"
