[terraform]: https://terraform.io
[oci]: https://cloud.oracle.com/cloud-infrastructure
[oci provider]: https://github.com/oracle/terraform-provider-oci/releases
[API signing]: https://docs.us-phoenix-1.oraclecloud.com/Content/API/Concepts/apisigningkey.htm
[Kubectl]: https://kubernetes.io/docs/tasks/tools/install-kubectl/

# Terraform Kubernetes Installer for Oracle Cloud Infrastructure

## About

The Kubernetes Installer for Oracle Cloud Infrastructure provides a Terraform-based Kubernetes installation for Oracle 
Cloud Infrastructure. It consists of a set of [Terraform][terraform] modules and an example base configuration that is 
used to provision and configure the resources needed to run a highly available and configurable Kubernetes cluster on [Oracle Cloud Infrastructure][oci] (OCI).

### Cluster Overview

Terraform is used to _provision_ the cloud infrastructure and any required local resources for the Kubernetes cluster including:

##### OCI Infrastructure

- Virtual Cloud Network (VCN) with dedicated subnets for etcd, masters, and workers in each availability domain
- Dedicated compute instances for etcd, Kubernetes master and worker nodes in each availability domain
- TCP/SSL OCI Load Balancer to to distribute traffic to the Kubernetes masters
- Private OCI Load Balancer to distribute traffic to the etcd cluster
- _Optional_ NAT instance for Internet-bound traffic when the input variable `network_access` is set to `private`
- 2048-bit SSH RSA Key-Pair for compute instances when not overridden by `ssh_private_key` and `ssh_public_key_openssh` input variabless
- Self-signed CA and TLS cluster certificates when not overridden by the input variables `ca_cert`, `ca_key`, etc.

##### Cluster Configuration

Terraform uses cloud-init scripts to handle the instance-level _configuration_ for instances in the Control Plane to 
configure:

- Highly Available (HA) Kubernetes master configuration
- Highly Available (HA) etcd cluster configuration
- Kubernetes Dashboard and kube-DNS cluster add-ons
- Kubernetes RBAC (role-based authorization control)
- Flannel/CNI container networking

The Terraform scripts also accept a number of other input variables that are detailed below to choose instance shapes and how they are placed across the availability domain (ADs), etc. If your requirements extend beyond the base configuration, the modules can be used to form your own customized configuration.

![](./docs/images/arch.jpg)

## Prerequisites

1. Download and install [Terraform][terraform] (v0.10.3 or later)
2. Download and install the [OCI Terraform Provider][oci provider] (v2.0.0 or later)
3. Create an Terraform configuration file at  `~/.terraformrc` that specifies the path to the OCI provider:
```
providers {
  oci = "<path_to_provider_binary>/terraform-provider-oci"
}
```
4. Create a _terraform.tfvars_ file in the project root that specifies your [API signature][API signing], tenancy, user, and compartment within OCI:

```bash
# start from the included example
$ cp terraform.example.tfvars terraform.tfvars
```
5.  Ensure you have [Kubectl][Kubectl] installed if you plan to interact with the cluster locally

## Quick start

To run the Terraform scripts, you'll first need to download and install the Terraform binary and [OCI Provider][oci provider] as well as OCI access. Check out the [prerequisites](README.md#prerequisites) section for more details.

The quickest way to get a Kubernetes cluster up and running on OCI is to simply use the base configuration defined in 
the top-level file `k8s-oci.tf`:

```bash
# initialize your Terraform configuration including the modules
$ terraform init

# optionally customize the deployment by overriding input variable defaults in terraform.tfvars as you see fit

# see what Terraform will do before actually doing it
$ terraform plan

# provision resources and stand-up k8s cluster on OCI
$ terraform apply
```

The Kubernetes cluster will be running after the configuration is applied successfully and the cloud-init scripts have been given time to finish asynchronously. Typically this takes around 5 minutes after `terraform apply` and will vary depending on the overall configuration, instance counts, and shapes.

### Access the Kubernetes API server


##### Access the cluster using kubectl

If you've chosen to configure a _public_ networks (i.e. `network_access=public`), you can use `kubectl` to 
interact with your cluster from your local machine using the kubeconfig found in the ./generated folder or using the `kubeconfig` Terraform output variable.

```bash
# warning: 0.0.0.0/0 is wide open. Consider limiting HTTPs ingress to smaller set of IPs.
$ terraform plan -var master_https_ingress=0.0.0.0/0
$ terraform apply -var master_https_ingress=0.0.0.0/0
# consider closing access off again using terraform apply -var master_https_ingress=10.0.0.0/16
```

```bash
$ export KUBECONFIG=`pwd`/generated/kubeconfig
$ kubectl cluster-info
$ kubectl get nodes
```

If you've chosen to configure a _private_ networks (i.e. `network_access=private`), you'll need to first SSH into the NAT instance, then to one of the private nodes in the cluster (similar to how you would use a bastion host):

```bash
$ terraform plan -var public_subnet_ssh_ingress=0.0.0.0/0
$ terraform apply -var public_subnet_ssh_ingress=0.0.0.0/0
$ terraform output ssh_private_key > generated/instances_id_rsa
$ chmod 600 generated/instances_id_rsa
$ scp -i generated/instances_id_rsa generated/instances_id_rsa opc@NAT_INSTANCE_PUBLIC_IP:/home/opc/
$ ssh -i generated/instances_id_rsa opc@NAT_INSTANCE_PUBLIC_IP
```

```bash
nat$ ssh -i /home/opc/instances_id_rsa opc@K8SMASTER_INSTANCE_PRIVATE_IP
master$ kubectl cluster-info
master$ kubectl get nodes 
```

Note, for easier access, consider setting up an SSH tunnel between your local host and the NAT instance.

##### Access the cluster using Kubernetes Dashboard

To access the Kubernetes Dashboard, use `kubectl proxy`:

```
kubectl proxy &
open http://localhost:8001/ui
```

##### Verifying your cluster:

If you've chosen to configure a public cluster, you can do a quick and automated verification of your cluster from 
your local machine by running the `cluster-check.sh` located in the `scripts` directory.  Note that this script requires your KUBECONFIG environment variable to be set (above), and SSH and HTTPs access to be open to etcd and worker nodes.

To temporarily open access SSH and HTTPs access for `cluster-check.sh`, add the following to your `terraform.tfvars` file:

```bash
# warning: 0.0.0.0/0 is wide open. remember to undo this.
etcd_ssh_ingress = "0.0.0.0/0"
master_ssh_ingress = "0.0.0.0/0"
worker_ssh_ingress = "0.0.0.0/0"
master_https_ingress = "0.0.0.0/0"
worker_nodeport_ingress = "0.0.0.0/0"
```

```bash
$ scripts/cluster-check.sh
```
```
[cluster-check.sh] Running some basic checks on Kubernetes cluster....
[cluster-check.sh]   Checking ssh connectivity to each node...
[cluster-check.sh]   Checking whether instance bootstrap has completed on each node...
[cluster-check.sh]   Checking Flannel's etcd key from each node...
[cluster-check.sh]   Checking whether expected system services are running on each node...
[cluster-check.sh]   Checking status of /healthz endpoint at each k8s master node...
[cluster-check.sh]   Checking status of /healthz endpoint at the LB...
[cluster-check.sh]   Running 'kubectl get nodes' a number or times through the master LB...

The Kubernetes cluster is up and appears to be healthy.
Kubernetes master is running at https://129.146.22.175:443
KubeDNS is running at https://129.146.22.175:443/api/v1/proxy/namespaces/kube-system/services/kube-dns
kubernetes-dashboard is running at https://129.146.22.175:443/ui
```

##### SSH into OCI Instances

If you've chosen to configure a public cluster, you can open access SSH access to your master nodes by adding the following to your `terraform.tfvars` file:

```bash
# warning: 0.0.0.0/0 is wide open. remember to undo this.
etcd_ssh_ingress = "0.0.0.0/0"
master_ssh_ingress = "0.0.0.0/0"
worker_ssh_ingress = "0.0.0.0/0"
```

```bash
# Create local SSH private key file logging into OCI instances
$ terraform output ssh_private_key > generated/instances_id_rsa
# Retrieve public IP for etcd nodes
$ terraform output etcd_public_ips
# Log in as user opc to the OEL OS
$ ssh -i `pwd`/generated/instances_id_rsa opc@ETCD_INSTANCE_PUBLIC_IP
# Retrieve public IP for k8s masters
$ terraform output master_public_ips
$ ssh -i `pwd`/generated/instances_id_rsa opc@K8SMASTER_INSTANCE_PUBLIC_IP
# Retrieve public IP for k8s workers
$ terraform output worker_public_ips
$ ssh -i `pwd`/generated/instances_id_rsa opc@K8SWORKER_INSTANCE_PUBLIC_IP
```

If you've chosen to configure a private cluster (i.e. `network_access=private`), you'll need to first SSH into the NAT instance, then to a worker, master, or etcd node:

```bash
$ terraform plan -var public_subnet_ssh_ingress=0.0.0.0/0
$ terraform apply -var public_subnet_ssh_ingress=0.0.0.0/0
$ terraform output ssh_private_key > generated/instances_id_rsa
$ chmod 600 generated/instances_id_rsa
$ scp -i generated/instances_id_rsa generated/instances_id_rsa opc@NAT_INSTANCE_PUBLIC_IP:/home/opc/
$ ssh -i generated/instances_id_rsa opc@NAT_INSTANCE_PUBLIC_IP
nat$ ssh -i /home/opc/instances_id_rsa opc@PRIVATE_IP
```


### Mandatory Input Variables:

#### OCI Provider Configuration

name                                | default                 | description
------------------------------------|-------------------------|-----------------
tenancy_ocid                        | None (required)         | Tenancy's OCI OCID
compartment_ocid                    | None (required)         | Compartment's OCI OCID
user_ocid                           | None (required)         | Users's OCI OCID
fingerprint                         | None (required)         | Fingerprint of the OCI user's public key
private_key_path                    | None (required)         | Private key file path of the OCI user's private key
region                              | us-phoenix-1            | String value of region to create resources

### Optional Input Variables:


#### Cluster Access Configuration

name                                | default                 | description
------------------------------------|-------------------------|------------
network_access                      | public                  | Clusters access can be `public` or `private`

##### _Public_ Network Access (default)

If `network_access=public`, instances in the cluster's control plane will be provisioned in _public_ subnets and automatically get both a public and private IP address. If the inbound security rules allow, you can communicate with them directly via their public IPs. 

The following input variables are used to configure the inbound security rules on the public etcd, master, and worker subnets:

name                                | default                 | description
------------------------------------|-------------------------|------------
etcd_cluster_ingress                | 10.0.0.0/16 (VCN only)  | A CIDR notation IP range that is allowed to access the etcd cluster
etcd_ssh_ingress                    | 10.0.0.0/16 (VCN only)  | A CIDR notation IP range that is allowed to SSH to etcd nodes
master_ssh_ingress                  | 10.0.0.0/16 (VCN only)  | A CIDR notation IP range that is allowed to access the master(s)
master_https_ingress                | 10.0.0.0/16 (VCN only)  | A CIDR notation IP range that is allowed to access the HTTPs port on the master(s)
worker_ssh_ingress                  | 10.0.0.0/16 (VCN only)  | A CIDR notation IP range that is allowed to SSH to worker(s)
worker_nodeport_ingress             | 10.0.0.0/16 (VCN only)  | A CIDR notation IP range that is allowed to access NodePorts (30000-32767) on the worker(s)

##### _Private_ Network Access

If `network_access=private`, instances in the cluster's control plane and their Load Balancers will be provisioned in _private_ subnets. In this scenario, we will also set up an instance in a public subnet to perform Network Address Translation (NAT) for instances in the private subnets so they can send outbound traffic. If your worker nodes need to accept incoming traffic from the Internet, an additional Load Balancer will need to be provisioned in the public subnet to route traffic to workers in the private subnets.

The following input variables are used to configure the inbound security rules for the NAT instance and any other 
instance or front-end Load Balancer in the public subnet:

name                                | default                 | description
------------------------------------|-------------------------|------------
public_subnet_ssh_ingress           | 0.0.0.0/0               | A CIDR notation IP range that is allowed to SSH to instances in the public subnet (including the NAT instance)
public_subnet_http_ingress          | 0.0.0.0/0               | A CIDR notation IP range that is allowed access to port 80 on instances in the public subnet
public_subnet_https_ingress         | 0.0.0.0/0               | A CIDR notation IP range that is allowed access to port 443 on instances in the public subnet
natInstanceShape                    | VM.Standard1.1          | OCI shape for the optional NAT instance. Size according to the amount of expected _outbound_ traffic from nodes and pods
natInstanceAd                       | 1                       | Availability Domain in which to provision NAT instance

*Note*

If `network_access=private`, you do not need to set the etcd, master, and worker security rules since they already allow all inbound traffic between instances in the VCN.

#### Instance Shape and Placement Configuration
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
etcd_lb_enabled                     | "true"                  | enable/disable the etcd load balancer. "true" use the etcd load balancer ip, "false" use a list of etcd instance ips
etcdLBShape                         | 100Mbps                 | etcd OCI Load Balancer shape / bandwidth
k8sMasterLBShape                    | 100Mbps                 | master OCI Load Balancer shape / bandwidth

#### TLS Certificates & SSH key pair
name                                | default                 | description
------------------------------------|-------------------------|------------
ca_cert                             | (generated)             | String value of PEM encoded CA certificate
ca_key                              | (generated)             | String value of PEM encoded CA private key
api_server_private_key              | (generated)             | String value of PEM private key of API server
api_server_cert                     | (generated)             | String value of PEM encoded certificate for API server
api_server_admin_token              | (generated)             | String value of the admin user's bearer token for API server
ssh_private_key                     | (generated)             | String value of PEM encoded SSH key pair for instances
ssh_public_key_openssh              | (generated)             | String value of OpenSSH encoded SSH key pair key for instances

#### Network Configuration
name                                | default                 | description
------------------------------------|-------------------------|------------
flannel_network_cidr                | 10.99.0.0/16            | A CIDR notation IP range to use for flannel

#### Software Versions Installed on OCI Instances

name                                | default                        | description
------------------------------------|--------------------------------|------------
docker_ver                          | 17.06.2.ol                     | Version of Docker to install
etcd_ver                            | v3.2.2                         | Version of etcd to install
flannel_ver                         | v0.7.1                         | Version of Flannel to install
k8s_ver                             | 1.7.4                          | Version of K8s to install (master and workers)
k8s_dns_ver                         | 1.14.2                         | Version of Kube DNS to install
k8s_dashboard_ver                   | 1.6.3                          | Version of Kubernetes dashboard to install
oracle_linux_image_name             | Oracle-Linux-7.4-2017.10.25-0  | Image name of an Oracle-Linux-7.X image

#### Docker logging configuration
name                                | default   | description
------------------------------------|-----------|--------------------------
etcd_docker_max_log_size            | 50m       |max size of the etcd docker container logs
etcd_docker_max_log_files           | 5         |max number of etcd docker logs to rotate
master_docker_max_log_size          | 50m       |max size of the k8smaster docker container logs
master_docker_max_log_files         | 5         |max number of k8smaster docker container logs to rotate
worker_docker_max_log_size          | 50m       |max size of the k8sworker docker container logs
worker_docker_max_log_files         | 5         |max number of k8s master docker container logs to rotate

#### Other
name                                | default                 | description
------------------------------------|-------------------------|------------
label_prefix                        | ""                      | Unique identifier to prefix to OCI resources


### Examples

#### Deploying a new cluster

Override any of the above input variables in your terraform.vars and run the plan and apply commands:

```bash
# verify what will change
$ terraform plan

# scale workers
$ terraform apply
```

#### Scaling k8s workers (in or out) using terraform apply

To scale workers in or out, adjust the `k8sWorkerAd1Count`, `k8sWorkerAd2Count`, or `k8sWorkerAd3Count` input 
variables in terraform.vars and run the plan and apply commands:

```bash
# verify changes
$ terraform plan

# scale workers (use -target=module.instances-k8sworker-adX to only target workers in a particular AD)
$ terraform apply
```

When scaling worker nodes _up_, you will need to wait for the node initialization to finish asynchronously before 
the new nodes will be seen with `kubectl get nodes`

When scaling worker nodes _down_, the instances/k8sworker module's user_data code will take care of running `kubectl drain` and `kubectl delete node` on the nodes being terminated.

#### Scaling k8s masters (in or out) using terraform apply

To scale the masters in or out, adjust the `k8sMasterAd1Count`, `k8sMasterAd2Count`, or `k8sMasterAd3Count` input variables in terraform.vars and run the plan and apply commands:

```bash
# verify changes
$ terraform plan

# scale master nodes
$ terraform apply
```

Similar to the initial deployment, you will need to wait for the node initialization to finish asynchronously.

#### Scaling etcd nodes (in or out) using terraform apply

Scaling the etcd nodes in or out after the initial deployment is not currently supported. Terminating all the nodes in the etcd cluster will result in data loss.

#### Replacing worker nodes using terraform taint

We can use `terraform taint` to worker instances in a particular AD as "tainted", which will cause
 them to be destroyed and recreated on the next apply. This can be a useful strategy for reverting local changes or 
 regenerating a misbehaving worker.

```bash
# taint all workers in AD1
terraform taint -module=instances-k8sworker-ad1 oci_core_instance.TFInstanceK8sWorker
# optionally taint workers in AD2 and AD3 or do so in a subsequent apply
# terraform taint -module=instances-k8sworker-ad2 oci_core_instance.TFInstanceK8sWorker
# terraform taint -module=instances-k8sworker-ad3 oci_core_instance.TFInstanceK8sWorker

# preview changes
$ terraform plan

# replace workers
$ terraform apply
```

#### Replacing masters using terraform taint

We can also use `terraform taint` to master instances in a particular AD as "tainted", which will cause
 them to be destroyed and recreated on the next apply. This can be a useful strategy for reverting local 
 changes or regenerating a misbehaving master.

```bash
# taint all masters in AD1
terraform taint -module=instances-k8smaster-ad1 oci_core_instance.TFInstanceK8sMaster
# optionally taint masters in AD2 and AD3 or do so in a subsequent apply
# terraform taint -module=instances-k8smaster-ad2 oci_core_instance.TFInstanceK8sMaster
# terraform taint -module=instances-k8smaster-ad3 oci_core_instance.TFInstanceK8sMaster

# preview changes
$ terraform plan

# replace workers
$ terraform apply
```

#### Replacing etcd cluster members using terraform taint

Replacing etcd cluster members after the initial deployment is not currently supported.

### Configure docker log sizes and rotation file counts
All docker containers currently are configured to use the json-file logging driver with the following settings:
```
max-size=50m  max-file=5
```
where:
```
   max-size: maximum size of log before it is rolled units(k,m, or g)  
   max-file: maximum number of files that can be present before oldest is removed  
   ```
To change this, add any desired modification to your terraform.tfvars file.  
For example, to change the k8sworker docker log file rotation from 5 to 3.  
```
worker_docker_max_log_files = "3"
```
To change the k8smaster docker log file size from 50m to 100m
```
master_docker_max_log_size = "100m"
```

## Known issues and limitations
* Scaling or replacing etcd members in or out after the initial deployment is currently unsupported
* Creating a service with `--type=LoadBalancer` is currently unsupported
* Failover or HA configuration for the NAT instance is currently unsupported

## Contributing

This project is open source. Oracle appreciates any contributions that are made by the open source community.

See [CONTRIBUTING](CONTRIBUTING.md) for details.

## Installed on OCI Instances

* Oracle Linux Enterprise (7.4)
* etcd - (default v3.2.2)
* flannel - (default v0.7.1)
* docker - (default 17.06.2.ol)
* apt-transport-https - (default 1.2.20)
* kubernetes - (default v1.7.4)
  * master(s) (`kube-apiserver`, `kube-controller-manager`, `kube-scheduler`, `kubernetes-cni`, `kubectl`)
  * worker(s) (`kubelet`, `kube-proxy`, `kubernetes-cni`, `kubectl`)
  * cluster add-ons: (`dashboard`, `kube-DNS`)
