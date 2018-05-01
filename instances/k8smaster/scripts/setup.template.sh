#!/bin/bash -x

EXTERNAL_IP=$(curl -s -m 10 http://whatismyip.akamai.com/)
NAMESPACE=$(echo -n "${domain_name}" | sed "s/\.oraclevcn\.com//g")
FQDN_HOSTNAME=$(getent hosts $(ip route get 1 | awk '{print $NF;exit}') | awk '{print $2}')

# Pull instance metadata
curl -sL --retry 3 http://169.254.169.254/opc/v1/instance/ | tee /tmp/instance_meta.json

ETCD_ENDPOINTS=${etcd_endpoints}
export HOSTNAME=$(hostname)

export IP_LOCAL=$(ip route show to 0.0.0.0/0 | awk '{ print $5 }' | xargs ip addr show | grep -Po 'inet \K[\d.]+')

SUBNET=$(getent hosts $IP_LOCAL | awk '{print $2}' | cut -d. -f2)

## k8s_ver swap option
######################################
k8sversion="${k8s_ver}"

if [[ $k8sversion =~ ^[0-1]+\.[0-7]+ ]]; then
    SWAP_OPTION=""
else
    SWAP_OPTION="--fail-swap-on=false"
fi

## etcd
######################################

## Disable TX checksum offloading so we don't break VXLAN
######################################
BROADCOM_DRIVER=$(lsmod | grep bnxt_en | awk '{print $1}')
if [[ -n "$${BROADCOM_DRIVER}" ]]; then
   echo "Disabling hardware TX checksum offloading"
   ethtool --offload $(ip -o -4 route show to default | awk '{print $5}') tx off
fi

# Download etcdctl client
curl -L --retry 3 https://github.com/coreos/etcd/releases/download/${etcd_ver}/etcd-${etcd_ver}-linux-amd64.tar.gz -o /tmp/etcd-${etcd_ver}-linux-amd64.tar.gz
tar zxf /tmp/etcd-${etcd_ver}-linux-amd64.tar.gz -C /tmp/ && cp /tmp/etcd-${etcd_ver}-linux-amd64/etcd* /usr/local/bin/

# Wait for etcd to become active (through the LB)
until [ $(/usr/local/bin/etcdctl --endpoints ${etcd_endpoints} cluster-health | grep '^cluster ' | grep -c 'is healthy$') == "1" ]; do
	echo "Waiting for etcd cluster to be healthy"
	sleep 1
done

## Docker
######################################
until yum -y install docker-engine-${docker_ver}; do sleep 1 && echo -n "."; done

cat <<EOF > /etc/sysconfig/docker
OPTIONS="--selinux-enabled --log-opt max-size=${docker_max_log_size} --log-opt max-file=${docker_max_log_files}"
DOCKER_CERT_PATH=/etc/docker
GOTRACEBACK=crash
EOF

systemctl daemon-reload
systemctl enable docker
systemctl start docker

# Output /etc/environment_params
echo "IPV4_PRIVATE_0=$IP_LOCAL" >>/etc/environment_params
echo "ETCD_IP=$ETCD_ENDPOINTS" >>/etc/environment_params
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
sudo sed -i  s/SELINUX=enforcing/SELINUX=permissive/ /etc/selinux/config
setenforce 0
systemctl stop firewalld.service
systemctl disable firewalld.service

## Install Flex Volume Driver for OCI
#####################################
mkdir -p /usr/libexec/kubernetes/kubelet-plugins/volume/exec/oracle~oci/
curl -L --retry 3 https://github.com/oracle/oci-flexvolume-driver/releases/download/${flexvolume_driver_version}/oci -o/usr/libexec/kubernetes/kubelet-plugins/volume/exec/oracle~oci/oci
chmod a+x /usr/libexec/kubernetes/kubelet-plugins/volume/exec/oracle~oci/oci
mv /root/flexvolume-driver-secret.yaml /usr/libexec/kubernetes/kubelet-plugins/volume/exec/oracle~oci/config.yaml

## Install kubelet, kubectl, and kubernetes-cni
###############################################
yum-config-manager --add-repo http://yum.kubernetes.io/repos/kubernetes-el7-x86_64
yum search -y kubernetes

VER_IN_REPO=$(repoquery --nvr --show-duplicates kubelet | sort --version-sort | grep ${k8s_ver} | tail -n 1)
if [[ -z "$${VER_IN_REPO}" ]]; then
   MAJOR_VER=$(echo ${k8s_ver} | cut -d. -f-2)
   echo "Falling back to latest version available in: $MAJOR_VER"
   VER_IN_REPO=$(repoquery --nvr --show-duplicates kubelet | sort --version-sort | grep $MAJOR_VER | tail -n 1)
   echo "Installing kubelet version: $VER_IN_REPO"
   yum install -y $VER_IN_REPO
   ## Replace kubelet binary since rpm at the exact k8s_ver was not available.
   curl -L --retry 3 http://storage.googleapis.com/kubernetes-release/release/v${k8s_ver}/bin/linux/amd64/kubelet -o /bin/kubelet && chmod 755 /bin/kubelet
else
   echo "Installing kubelet version: $VER_IN_REPO"
   yum install -y $VER_IN_REPO
fi

# Check if kubernetes-cni was automatically installed as a dependency
K8S_CNI=$(rpm -qa | grep kubernetes-cni)
if [[ -z "$${K8S_CNI}" ]]; then
   echo "Installing: $K8S_CNI"
   yum install -y kubernetes-cni
else
   echo "$K8S_CNI already installed"
fi

curl -L --retry 3 http://storage.googleapis.com/kubernetes-release/release/v${k8s_ver}/bin/linux/amd64/kubectl -o /bin/kubectl && chmod 755 /bin/kubectl

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

## kubelet for the master
systemctl daemon-reload
read NODE_ID_0 NODE_ID_1 <<< $(jq -r '.id' /tmp/instance_meta.json | perl -pe 's/(.*?\.){4}\K/ /g' | perl -pe 's/\.+\s/ /g')
sed -e "s/__FQDN_HOSTNAME__/$FQDN_HOSTNAME/g" \
    -e "s/__SWAP_OPTION__/$SWAP_OPTION/g" \
    -e "s/__NODE_ID_PREFIX__/$NODE_ID_0/g" \
    -e "s/__NODE_ID_SUFFIX__/$NODE_ID_1/g" \
     /root/services/kubelet.service >/etc/systemd/system/kubelet.service
systemctl daemon-reload
systemctl enable kubelet
systemctl start kubelet

until kubectl get all; do sleep 1 && echo -n "."; done

## Wait for k8s master to be available. There is a possible race on pod networks otherwise.
until [ "$(curl localhost:8080/healthz 2>/dev/null)" == "ok" ]; do
	sleep 3
done


case "${kubernetes_network_plugin}" in
  flannel)
    # Install flannel
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/${flannel_ver}/Documentation/k8s-manifests/kube-flannel-rbac.yml

    ## This could be done better
    curl -sSL https://raw.githubusercontent.com/coreos/flannel/${flannel_ver}/Documentation/kube-flannel.yml | \
        sed -e "s#10.244.0.0/16#${flannel_network_cidr}#g" \
            -e "s#vxlan#${flannel_backend}#g" | \
        kubectl apply -f -
    ;;
  canal)
    # Setup Kube CNI - canal
    # https://docs.projectcalico.org/v3.0/getting-started/kubernetes/installation/hosted/canal/
    kubectl apply -f https://docs.projectcalico.org/v3.0/getting-started/kubernetes/installation/hosted/canal/rbac.yaml
    curl -sSL kubectl apply -f https://docs.projectcalico.org/v3.0/getting-started/kubernetes/installation/hosted/canal/canal.yaml | \
        sed -e "s#10.244.0.0/16#${flannel_network_cidr}#g" \
            -e "s#vxlan#${flannel_backend}#g" | \
        kubectl apply -f -
    ;;
esac

# Install oci cloud controller manager
kubectl apply -f /root/cloud-controller-secret.yaml
kubectl apply -f https://github.com/oracle/oci-cloud-controller-manager/releases/download/${cloud_controller_version}/oci-cloud-controller-manager-rbac.yaml
curl -sSL https://github.com/oracle/oci-cloud-controller-manager/releases/download/${cloud_controller_version}/oci-cloud-controller-manager.yaml | \
    sed -e "s#10.244.0.0/16#${flannel_network_cidr}#g" | \
    kubectl apply -f -

## install kube-dns
kubectl create -f /root/services/kube-dns.yaml

## install kubernetes-dashboard
kubectl create -f /root/services/kubernetes-dashboard.yaml

## Install Volume Provisioner of OCI
kubectl create secret generic oci-volume-provisioner -n kube-system --from-file=config.yaml=/root/volume-provisioner-secret.yaml
kubectl apply -f https://github.com/oracle/oci-volume-provisioner/releases/download/${volume_provisioner_version}/oci-volume-provisioner-rbac.yaml
kubectl apply -f https://github.com/oracle/oci-volume-provisioner/releases/download/${volume_provisioner_version}/oci-volume-provisioner.yaml
kubectl apply -f https://github.com/oracle/oci-volume-provisioner/releases/download/${volume_provisioner_version}/storage-class.yaml
kubectl apply -f https://github.com/oracle/oci-volume-provisioner/releases/download/${volume_provisioner_version}/storage-class-ext3.yaml

## Mark OCI StorageClass as the default
kubectl patch storageclass oci -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

rm -f /root/volume-provisioner-secret.yaml

yum install -y nfs-utils

echo "Finished running setup.sh"
