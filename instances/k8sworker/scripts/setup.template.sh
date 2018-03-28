#!/bin/bash -x

EXTERNAL_IP=$(curl -s -m 10 http://whatismyip.akamai.com/)
NAMESPACE=$(echo -n "${domain_name}" | sed "s/\.oraclevcn\.com//g")
FQDN_HOSTNAME=$(getent hosts $(ip route get 1 | awk '{print $NF;exit}') | awk '{print $2}')

# Pull instance metadata
curl -sL --retry 3 http://169.254.169.254/opc/v1/instance/ | tee /tmp/instance_meta.json

## Create policy file that blocks autostart of services on install
printf '#!/bin/sh\necho "All runlevel operations denied by policy" >&2\nexit 101\n' >/tmp/policy-rc.d && chmod +x /tmp/policy-rc.d
export K8S_API_SERVER_LB=${master_lb}
export RANDFILE=$(mktemp)
export HOSTNAME=$(hostname)

export IP_LOCAL=$(ip route show to 0.0.0.0/0 | awk '{ print $5 }' | xargs ip addr show | grep -Po 'inet \K[\d.]+')

SUBNET=$(getent hosts $IP_LOCAL | awk '{print $2}' | cut -d. -f2)
export WORKER_IP=$IP_LOCAL

## k8s_ver swap option
######################################
k8sversion="${k8s_ver}"

if [[ $k8sversion =~ ^[0-1]+\.[0-7]+ ]]; then
    SWAP_OPTION=""
else
    SWAP_OPTION="--fail-swap-on=false"
fi

## Disable TX checksum offloading so we don't break VXLAN
######################################
BROADCOM_DRIVER=$(lsmod | grep bnxt_en | awk '{print $1}')
if [[ -n "$${BROADCOM_DRIVER}" ]]; then
   echo "Disabling hardware TX checksum offloading"
   ethtool --offload $(ip -o -4 route show to default | awk '{print $5}') tx off
fi

## Setup NVMe drives and mount at /var/lib/docker
######################################
NVMEVGNAME="NVMeVG"
NVMELVNAME="DockerVol"
NVMEDEVS=$(lsblk -I259 -pn -oNAME -d)
if [[ ! -z "$${NVMEDEVS}" ]]; then
    lvs $${NVMEVGNAME}/$${NVMELVNAME} --noheadings --logonly 1>/dev/null
    if [ $$? -ne 0 ]; then
	pvcreate $${NVMEDEVS}
	vgcreate $${NVMEVGNAME} $${NVMEDEVS}
	lvcreate --extents 100%FREE --name $${NVMELVNAME} $${NVMEVGNAME} $${NVMEDEVS}
	mkfs -t xfs /dev/$${NVMEVGNAME}/$${NVMELVNAME}
	mkdir -p /var/lib/docker
	mount -t xfs /dev/$${NVMEVGNAME}/$${NVMELVNAME} /var/lib/docker
	echo "/dev/$${NVMEVGNAME}/$${NVMELVNAME} /var/lib/docker xfs rw,relatime,seclabel,attr2,inode64,noquota 0 2" >> /etc/fstab
    fi
fi

## Login iSCSI volume mount and create filesystem
######################################
iqn=$(iscsiadm --mode discoverydb --type sendtargets --portal 169.254.2.2:3260 --discover| cut -f2 -d" ")

if [ -n "$${iqn}" ]; then
    echo "iSCSI Login $${iqn}"
    iscsiadm -m node -o new -T $${iqn} -p 169.254.2.2:3260
    iscsiadm -m node -o update -T $${iqn} -n node.startup -v automatic
    iscsiadm -m node -T $${iqn} -p 169.254.2.2:3260 -l
    # Wait for device to apear...
    until [[ -e "/dev/disk/by-path/ip-169.254.2.2:3260-iscsi-$${iqn}-lun-1" ]]; do sleep 1 && echo -n "."; done
    # If the volume has been created and formatted before but it's just a new instance this may fail
    # but if so ignore and carry on.
    mkfs -t xfs "/dev/disk/by-path/ip-169.254.2.2:3260-iscsi-$${iqn}-lun-1";
    echo "$$(readlink -f /dev/disk/by-path/ip-169.254.2.2:3260-iscsi-$${iqn}-lun-1) ${worker_iscsi_volume_mount} xfs defaults,noatime,_netdev 0 2" >> /etc/fstab
    mkdir -p ${worker_iscsi_volume_mount}
    mount -t xfs "/dev/disk/by-path/ip-169.254.2.2:3260-iscsi-$${iqn}-lun-1" ${worker_iscsi_volume_mount}
fi

until yum -y install docker-engine-${docker_ver}; do sleep 1 && echo -n "."; done

cat <<EOF > /etc/sysconfig/docker
OPTIONS="--selinux-enabled --log-opt max-size=${docker_max_log_size} --log-opt max-file=${docker_max_log_files}"
DOCKER_CERT_PATH=/etc/docker
GOTRACEBACK=crash
EOF

systemctl daemon-reload
systemctl enable docker
systemctl start docker

## Output /etc/environment_params
######################################
echo "IPV4_PRIVATE_0=$IP_LOCAL" >>/etc/environment_params
echo "ETCD_IP=$ETCD_ENDPOINTS" >>/etc/environment_params
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
sudo sed -i  s/SELINUX=enforcing/SELINUX=permissive/ /etc/selinux/config
systemctl stop firewalld.service
systemctl disable firewalld.service

## Install Flex Volume Driver for OCI
#####################################
mkdir -p /usr/libexec/kubernetes/kubelet-plugins/volume/exec/oracle~oci/
curl -L --retry 3 https://github.com/oracle/oci-flexvolume-driver/releases/download/${flexvolume_driver_version}/oci -o/usr/libexec/kubernetes/kubelet-plugins/volume/exec/oracle~oci/oci
chmod a+x /usr/libexec/kubernetes/kubelet-plugins/volume/exec/oracle~oci/oci


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

## FQDN constructed from live environment since DNS label for the subnet is optional
sed -e "s/__FQDN_HOSTNAME__/$FQDN_HOSTNAME/g" /etc/kubernetes/manifests/kube-proxy.yaml >/tmp/kube-proxy.yaml
cat /tmp/kube-proxy.yaml >/etc/kubernetes/manifests/kube-proxy.yaml

## kubelet for the worker
######################################
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
    -e "s/__SWAP_OPTION__/$SWAP_OPTION/g" \
    /root/services/kubelet.service > /etc/systemd/system/kubelet.service

${reverse_proxy_setup}
## Wait for k8s master to be available. There is a possible race on pod networks otherwise.
until [ "$(curl -k --cert /etc/kubernetes/ssl/apiserver.pem --key /etc/kubernetes/ssl/apiserver-key.pem $K8S_API_SERVER_LB/healthz 2>/dev/null)" == "ok" ]; do
	sleep 3
done

# Setup CUDA devices before starting kubelet, so it detects the gpu(s)
/sbin/modprobe nvidia
if [ "$?" -eq 0 ]; then
	# Create the /dev/nvidia* files by running nvidia-smi
	nvidia-smi
fi

/sbin/modprobe nvidia-uvm
if [ "$?" -eq 0 ]; then
	# Find out the major device number used by the nvidia-uvm driver
	DEVICE=$(grep nvidia-uvm /proc/devices | awk '{print $1}')
	mknod -m 666 /dev/nvidia-uvm c $DEVICE 0
fi

sleep $[ ( $RANDOM % 10 )  + 1 ]s
systemctl daemon-reload
systemctl enable kubelet
systemctl start kubelet

yum install -y nfs-utils

######################################
echo "Finished running setup.sh"
