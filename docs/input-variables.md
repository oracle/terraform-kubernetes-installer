# Customizing the Deployment with Input Variables

## Mandatory Input Variables:

### OCI Provider Configuration

name                                | default                 | description
------------------------------------|-------------------------|-----------------
tenancy_ocid                        | None (required)         | Tenancy's OCI OCID
compartment_ocid                    | None (required)         | Compartment's OCI OCID
user_ocid                           | None (required)         | Users's OCI OCID
fingerprint                         | None (required)         | Fingerprint of the OCI user's public key
private_key_path                    | None (required)         | Private key file path of the OCI user's private key
region                              | us-phoenix-1            | String value of region to create resources

## Optional Input Variables:

### Network Access Configuration

name                                | default     | description
------------------------------------|-------------|------------
control_plane_subnet_access         | public      | Whether instances in the control plane are launched in a public or private subnets
k8s_master_lb_access                | public      | Whether the Kubernetes Master Load Balancer is launched in a public or private subnets


#### _Public_ Network Access (default)

![](./images/public_cp_subnet_access.jpg)

When `control_plane_subnet_access=public` and `k8s_master_lb_access=public`, control plane instances and the Kubernetes Master Load Balancer are provisioned in _public_ subnets and automatically get both a public and private IP address. If the inbound security rules allow, you can communicate with them directly via their public IPs. 

The following input variables are used to configure the inbound security rules on the public etcd, master, and worker subnets:

name                                | default                 | description
------------------------------------|-------------------------|------------
etcd_cluster_ingress                | 10.0.0.0/16 (VCN only)  | A CIDR notation IP range that is allowed to access the etcd cluster
etcd_ssh_ingress                    | 10.0.0.0/16 (VCN only)  | A CIDR notation IP range that is allowed to SSH to etcd nodes
master_ssh_ingress                  | 10.0.0.0/16 (VCN only)  | A CIDR notation IP range that is allowed to access the master(s)
master_https_ingress                | 10.0.0.0/16 (VCN only)  | A CIDR notation IP range that is allowed to access the HTTPs port on the master(s)
worker_ssh_ingress                  | 10.0.0.0/16 (VCN only)  | A CIDR notation IP range that is allowed to SSH to worker(s)
worker_nodeport_ingress             | 10.0.0.0/16 (VCN only)  | A CIDR notation IP range that is allowed to access NodePorts (30000-32767) on the worker(s)

#### _Private_ Network Access

![](./images/private_cp_subnet_private_lb_access.jpg)

When `control_plane_subnet_access=private` and `k8s_master_lb_access=private`, control plane instances and the Kubernetes Master Load Balancer
 are provisioned in _private_ subnets. In this scenario, we will also set up an instance in a public subnet to 
 perform  Network Address Translation (NAT) for instances in the private subnets so they can send outbound traffic. 
 If your worker nodes need to accept incoming traffic from the Internet, an additional front-end Load Balancer will 
 need to be provisioned in the public subnet to route traffic to workers in the private subnets.


The following input variables are used to configure the inbound security rules for the NAT instance(s) and any other instance or front-end Load Balancer in the public subnet:

name                                | default                 | description
------------------------------------|-------------------------|------------
public_subnet_ssh_ingress           | 0.0.0.0/0               | A CIDR notation IP range that is allowed to SSH to instances in the public subnet (including NAT instances)
public_subnet_http_ingress          | 0.0.0.0/0               | A CIDR notation IP range that is allowed access to port 80 on instances in the public subnet
public_subnet_https_ingress         | 0.0.0.0/0               | A CIDR notation IP range that is allowed access to port 443 on instances in the public subnet
natInstanceShape                    | VM.Standard1.1          | OCI shape for the optional NAT instance. Size according to the amount of expected _outbound_ traffic from nodes and pods
nat_instance_ad1_enabled            | true                    | whether to provision a NAT instance in AD 1 (only used when control_plane_subnet_access=private)
nat_instance_ad2_enabled            | false                   | whether to provision a NAT instance in AD 2 (only used when control_plane_subnet_access=private)
nat_instance_ad3_enabled            | false                   | whether to provision a NAT instance in AD 3 (only used when control_plane_subnet_access=private)

*Note*

Even though we can configure a NAT instance per AD, this [diagram](./images/private_cp_subnet_public_lb_failure.jpg) illustrates that each NAT Instance is still represents a single point of failure for the private subnet that routes outbound traffic to it.

#### _Private_ and _Public_ Network Access

![](./images/private_cp_subnet_public_lb_access.jpg)

It is also valid to set `control_plane_subnet_access=private` while keeping `k8s_master_lb_access=public`. In this scenario, instances in the 
cluster's control plane will still provisioned in _private_ subnets and require NAT instance(s). However, the Load 
Balancer for your back-end Kubernetes Master(s) will be launched in a public subnet and will therefore be accessible 
over the Internet if the inbound security rules allow.

*Note*

When `control_plane_subnet_access=private`, you still cannot SSH directly into your instances without going through a NAT instance. 

### Compute Instance Configuration
name                                | default                 | description
------------------------------------|-------------------------|------------
etcdShape                           | VM.Standard1.1          | OCI shape for etcd nodes
k8sMasterShape                      | VM.Standard1.1          | OCI shape for k8s master(s)
k8sWorkerShape                      | VM.Standard1.2          | OCI shape for k8s worker(s)
k8sMasterAd1Count                   | 1                       | number of k8s masters to create in Availability Domain 1
k8sMasterAd2Count                   | 0                       | number of k8s masters to create in Availability Domain 2
k8sMasterAd3Count                   | 0                       | number of k8s masters to create in Availability Domain 3
k8sWorkerAd1Count                   | 1                       | number of k8s workers to create in Availability Domain 1
k8sWorkerAd2Count                   | 0                       | number of k8s workers to create in Availability Domain 2
k8sWorkerAd3Count                   | 0                       | number of k8s workers to create in Availability Domain 3
etcdAd1Count                        | 1                       | number of etcd nodes to create in Availability Domain 1
etcdAd2Count                        | 0                       | number of etcd nodes to create in Availability Domain 2
etcdAd3Count                        | 0                       | number of etcd nodes to create in Availability Domain 3
worker_iscsi_volume_size            | unset                   | optional size of an iSCSI volume to attach to each worker
worker_iscsi_volume_mount           | /var/lib/docker         | optional mount path of iSCSI volume when worker_iscsi_volume_size is set
etcd_iscsi_volume_create            | false                   | boolean flag indicating whether or not to attach an iSCSI volume to attach to each etcd node
etcd_iscsi_volume_size              | 50                      | size in GBs of volume when etcd_iscsi_volume_create is set
etcd_lb_enabled                     | "true"                  | enable/disable the etcd load balancer. "true" use the etcd load balancer ip, "false" use a list of etcd instance ips
etcdLBShape                         | 100Mbps                 | etcd cluster OCI Load Balancer shape / bandwidth
k8sMasterLBShape                    | 100Mbps                 | Kubernetes Master OCI Load Balancer shape / bandwidth

### TLS Certificates & SSH key pair
name                                | default                 | description
------------------------------------|-------------------------|------------
ca_cert                             | (generated)             | String value of PEM encoded CA certificate
ca_key                              | (generated)             | String value of PEM encoded CA private key
api_server_private_key              | (generated)             | String value of PEM private key of API server
api_server_cert                     | (generated)             | String value of PEM encoded certificate for API server
api_server_admin_token              | (generated)             | String value of the admin user's bearer token for API server
ssh_private_key                     | (generated)             | String value of PEM encoded SSH key pair for instances
ssh_public_key_openssh              | (generated)             | String value of OpenSSH encoded SSH key pair key for instances

### Network Configuration
name                                | default                 | description
------------------------------------|-------------------------|------------
flannel_network_cidr                | 10.99.0.0/16            | A CIDR notation IP range to use for flannel
flannel_backend                     | VXLAN                   | Backend to use for Flannel, choices are vxlan, udp, and host-gw

### Software Versions Installed on OCI Instances
name                                | default            | description
------------------------------------|--------------------|------------
docker_ver                          | 17.06.2.ol                     | Version of Docker to install
etcd_ver                            | v3.2.2                         | Version of etcd to install
flannel_ver                         | v0.7.1                         | Version of Flannel to install
k8s_ver                             | 1.7.10                         | Version of K8s to install (master and workers)
k8s_dns_ver                         | 1.14.2                         | Version of Kube DNS to install
k8s_dashboard_ver                   | 1.6.3                          | Version of Kubernetes dashboard to install
master_ol_image_name                | Oracle-Linux-7.4-2018.01.10-0  | Image name of an Oracle-Linux-7.X image to use for masters
worker_ol_image_name                | Oracle-Linux-7.4-2018.01.10-0  | Image name of an Oracle-Linux-7.X image to use for workers
etcd_ol_image_name                  | Oracle-Linux-7.4-2018.01.10-0  | Image name of an Oracle-Linux-7.X image to use for etcd nodes
nat_ol_image_name                   | Oracle-Linux-7.4-2018.01.10-0  | Image name of an Oracle-Linux-7.X image to use for NAT instances (if applicable)

#### Docker logging configuration
name                                | default   | description
------------------------------------|-----------|--------------------------
etcd_docker_max_log_size            | 50m       |max size of the etcd docker container logs
etcd_docker_max_log_files           | 5         |max number of etcd docker logs to rotate
master_docker_max_log_size          | 50m       |max size of the k8smaster docker container logs
master_docker_max_log_files         | 5         |max number of k8smaster docker container logs to rotate
worker_docker_max_log_size          | 50m       |max size of the k8sworker docker container logs
worker_docker_max_log_files         | 5         |max number of k8s master docker container logs to rotate

### Other
name                                | default                 | description
------------------------------------|-------------------------|------------
label_prefix                        | ""                      | Unique identifier to prefix to OCI resources
