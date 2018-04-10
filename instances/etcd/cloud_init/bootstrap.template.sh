#!/bin/bash -x

# Turn off SELinux
sudo sed -i  s/SELINUX=enforcing/SELINUX=permissive/ /etc/selinux/config
setenforce 0

# Set working dir
cd /home/opc

# enable ol7 addons
yum-config-manager --disable ol7_UEKR3
yum-config-manager --enable ol7_addons ol7_latest ol7_UEKR4 ol7_optional ol7_optional_latest

# Install Docker
until yum -y install docker-engine-${docker_ver}; do sleep 1 && echo -n "."; done

cat <<EOF > /etc/sysconfig/docker
OPTIONS="--selinux-enabled --log-opt max-size=${docker_max_log_size} --log-opt max-file=${docker_max_log_files}"
DOCKER_CERT_PATH=/etc/docker
GOTRACEBACK=crash
EOF

# Start Docker
systemctl daemon-reload
systemctl enable docker
systemctl restart docker

docker info

###################
# Drop firewall rules
iptables -F

###################
# etcd

# Get IP Address of self
IP_LOCAL=$(ip route show to 0.0.0.0/0 | awk '{ print $5 }' | xargs ip addr show | grep -Po 'inet \K[\d.]+')
SUBNET=$(getent hosts $IP_LOCAL | awk '{print $2}' | cut -d. -f2)

HOSTNAME=$(hostname)
FQDN_HOSTNAME="$(getent hosts $IP_LOCAL | awk '{print $2}')"

## Login iSCSI volume mount and create filesystem at /etcd
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
    echo "$$(readlink -f /dev/disk/by-path/ip-169.254.2.2:3260-iscsi-$${iqn}-lun-1) /etcd xfs defaults,noatime,_netdev 0 2" >> /etc/fstab
    mkdir -p  /etcd
    mount -t xfs "/dev/disk/by-path/ip-169.254.2.2:3260-iscsi-$${iqn}-lun-1"  /etcd
fi

docker run -d \
        --restart=always \
	-p 2380:2380 -p 2379:2379 \
	-v /etc/ssl/certs/ca-bundle.crt:/etc/ssl/certs/ca-bundle.crt \
	-v /etcd:/$HOSTNAME.etcd \
	--net=host \
	quay.io/coreos/etcd:${etcd_ver} \
	/usr/local/bin/etcd \
	-name $HOSTNAME \
	-advertise-client-urls http://$IP_LOCAL:2379 \
	-listen-client-urls http://$IP_LOCAL:2379,http://127.0.0.1:2379 \
	-listen-peer-urls http://0.0.0.0:2380 \
	-discovery ${etcd_discovery_url}

# wait for etcd to become active
while ! curl -sf -o /dev/null http://$FQDN_HOSTNAME:2379/v2/keys/; do
	sleep 1
	echo "Try again"
done

# Download etcdctl client etcd_ver
while ! curl -L https://github.com/coreos/etcd/releases/download/${etcd_ver}/etcd-${etcd_ver}-linux-amd64.tar.gz -o /tmp/etcd-${etcd_ver}-linux-amd64.tar.gz; do
	sleep 1
	((secs++)) && ((secs==10)) && break
	echo "Try again"
done
tar zxf /tmp/etcd-${etcd_ver}-linux-amd64.tar.gz -C /tmp/ && cp /tmp/etcd-${etcd_ver}-linux-amd64/etcd* /usr/local/bin/
