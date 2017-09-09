#!/bin/bash -x

# Set working dir
cd /home/ubuntu

# Install Docker dependencies
until apt-get install -y aufs-tools cgroupfs-mount libltdl7; do sleep 1 && echo -n "."; done

# Download Docker
curl -L --retry 3 https://download.docker.com/linux/ubuntu/dists/xenial/pool/stable/amd64/${docker_ver}.deb -o /tmp/${docker_ver}.deb

# Install Docker
until dpkg -i /tmp/${docker_ver}.deb; do sleep 1 && echo -n "."; done

###################
# Drop firewall rules
iptables -F

###################
# etcd

# Get IP Adress of self
IP_LOCAL=$(ip route show to 0.0.0.0/0 | awk '{ print $5 }' | xargs ip addr show | grep -Po 'inet \K[\d.]+')
SUBNET=$(getent hosts $IP_LOCAL | awk '{print $2}' | cut -d. -f2)

HOSTNAME=$(hostname)
FQDN_HOSTNAME="$(getent hosts $IP_LOCAL | awk '{print $2}')"

docker run -d \
	-p 2380:2380 -p 2379:2379 \
	-v /etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt \
	--net=host \
	quay.io/coreos/etcd:${etcd_ver} \
	/usr/local/bin/etcd \
	-name $HOSTNAME \
	-advertise-client-urls http://$IP_LOCAL:2379 \
	-listen-client-urls http://$IP_LOCAL:2379,http://127.0.0.1:2379 \
	-listen-peer-urls http://0.0.0.0:2380 \
	-discovery ${etcd_discovery_url}

# download etcdctl client  etcd_ver
curl -L --retry 3 https://github.com/coreos/etcd/releases/download/${etcd_ver}/etcd-${etcd_ver}-linux-amd64.tar.gz -o /tmp/etcd-${etcd_ver}-linux-amd64.tar.gz
tar zxf /tmp/etcd-${etcd_ver}-linux-amd64.tar.gz -C /tmp/ && cp /tmp/etcd-${etcd_ver}-linux-amd64/etcd* /usr/local/bin/

# Generate a flannel configuration that we will store into etcd using curl.
cat >/tmp/flannel-network.json <<EOF
{
  "Network": "${flannel_network_cidr}",
  "Subnetlen": ${flannel_network_subnetlen},
  "Backend": {
    "Type": "${flannel_backend}",
    "VNI" : 1
  }
}
EOF

# wait for etcd to become active
while ! curl -sf -o /dev/null http://$FQDN_HOSTNAME:2379/v2/keys/; do
	sleep 1
	echo "Try again"
done

# put the flannel config in etcd
curl -sf -L http://$FQDN_HOSTNAME:2379/v2/keys/flannel/network/config -X PUT --data-urlencode value@/tmp/flannel-network.json
