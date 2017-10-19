[terraform]: https://terraform.io
[bmcs]: https://cloud.oracle.com/en_US/bare-metal
[oci provider]: https://github.com/oracle/terraform-provider-oci/releases
[SSH key pair]: https://docs.us-phoenix-1.oraclecloud.com/Content/GSG/Tasks/creatingkeys.htm
[API signing]: https://docs.us-phoenix-1.oraclecloud.com/Content/API/Concepts/apisigningkey.htm
[Kubectl]: https://kubernetes.io/docs/tasks/tools/install-kubectl/

# Terraform Kubernetes Installer for Oracle Cloud Infrastructure

## About

The Kubernetes Installer for Oracle Cloud Infrastructure provides a Terraform-based Kubernetes installation for Oracle 
Cloud Infrastructure. It consists of a set of [Terraform][terraform] modules and an example base configuration that is 
used to provision and configure the resources needed to run a highly available and configurable Kubernetes cluster on [Oracle Cloud Infrastructure][bmcs] (OCI).

## Cluster Configuration Overview

The base Terraform infrastructure configuration and default variables provision:

- a Virtual Cloud Network with a CIDR block of 10.0.0.0/16 and dedicated public subnets for etcd, workers, and masters
- a dedicated set of Instances for the Kubernetes control plane to run on
- a _public_ OCI TCP/SSL Load Balancer to front-end the K8s API server cluster
- a _private_ OCI Load Balancer to front-end the etcd cluster

The base Kubernetes cluster configuration includes:

- 3 back-end etcd instances - one for each availability domain
- 3 back-end k8s master instances - one for each availability domain
- 3 k8s workers instances - one for each availability domain
- self-signed cluster certificates for _authenticating_ API requests
- Kubernetes RBAC (role-based authorization control) for _authorizing_ API requests
- Flannel/CNI for handling multi-host container networking

The base infrastructure and cluster configuration also accept input variables that allow you to specify the instance 
shapes and how they are placed across the availability domain (ADs). If your requirements extend beyond the base 
configuration, the modules can be used to form your own customized configuration.

![](./docs/images/arch.jpg)


## Prerequisites

1. Download and install [Terraform][terraform]
2. Download and install the [OCI Terraform Provider][oci provider] (v2.0.0 or later)
3. Create an Terraform configuration file at  `~/.terraformrc` that specifies the path to the OCI provider:
```
providers {
  oci = "<path_to_provider_binary>/terraform-provider-oci"
}
```
4. Create a _terraform.tfvars_ file in the project root that specifies your [API signature](API signing), tenancy, user, and compartment within OCI:

```bash
# start from the included example
$ cp terraform.example.tfvars terraform.tfvars
```
5.  Ensure you have [Kubectl][Kubectl] installed

## Quick start

To run the Terraform scripts, you'll first need to download and install the Terraform binary and [OCI Provider][bmcs provider] as well as OCI access. Check out the [prerequisites](README.md#prerequisites) section for more details.

The quickest way to get a Kubernetes cluster up and running on OCI is to simply use the base configuration defined in 
the top-level file `k8s-oci.tf`:

```bash
# initialize your Terraform configuration including the modules
$ terraform init

# optionally customize the deployment by overriding input variable defaults in `terraform.tfvars` as you see fit

# see what Terraform will do before actually doing it
$ terraform plan

# provision resources and stand-up k8s cluster on OCI
$ terraform apply
```

The Kubernetes cluster will be running after the configuration is applied successfully and the cluster installation 
scripts have been given time to finish asynchronously. Typically this takes around 5 minutes after `terraform apply` 
and will vary depending on the instance counts and shapes.

#### Access the Kubernetes API server

The master, worker, and etcd security groups only allow VCN ingress (10.0.0.0/16) by default. 

To open access HTTPs access to your master API server, which will enable the Kubernetes Dashboard and kubectl to be 
reachable from the outside, run:

```bash
# warning: 0.0.0.0/0 is wide open. Consider limiting HTTPs ingress to smaller set of IPs.
$ terraform plan -var master_https_ingress=0.0.0.0/0
$ terraform apply -var master_https_ingress=0.0.0.0/0
# consider closing access off again using terraform apply -var master_https_ingress=10.0.0.0/16
```

##### Access the cluster using kubectl

You can also use `kubectl` to interact with your cluster using the kubeconfig found in the ./generated folder or using the `kubeconfig` Terraform output variable.

```bash
$ export KUBECONFIG=`pwd`/generated/kubeconfig
$ kubectl cluster-info
$ kubectl get nodes
```

##### Access the cluster using Kubernetes Dashboard

To access the Kubernetes Dashboard, use `kubectl proxy`:

```
kubectl proxy &
open http://localhost:8001/ui
```

##### Verifying your cluster:

To do a quick and automated verification of your cluster, run the `cluster-check.sh` located in the `scripts` directory.  Note that this script requires your KUBECONFIG enviornment variable to be set (above), and SSH and HTTPs access to be open to etcd and worker nodes.

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

#### SSH into OCI Instances

To open access SSH access to your master nodes, add the following to your `terraform.tfvars` file:

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
$ ssh -i `pwd`/generated/instances_id_rsa opc@ETCD_INSTANCE_IP
# Retrieve public IP for k8s masters
$ terraform output master_public_ips
$ ssh -i `pwd`/generated/instances_id_rsa opc@K8SMASTER_INSTANCE_IP
# Retrieve public IP for k8s workers
$ terraform output worker_public_ips
$ ssh -i `pwd`/generated/instances_id_rsa opc@K8SWORKER_INSTANCE_IP
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

#### Instance Shape and Placement Configuration
name                                | default                 | description
------------------------------------|-------------------------|------------
etcdShape                           | VM.Standard1.1          | OCI shape for etcd nodes
k8sMasterShape                      | VM.Standard1.1          | OCI shape for k8s master(s)
k8sWorkerShape                      | VM.Standard1.2          | OCI shape for k8s worker(s)
k8sMasterAd1Count                   | 1                       | number of k8s masters to create in AD1
k8sMasterAd2Count                   | 0                       | number of k8s masters to create in AD2
k8sMasterAd3Count                   | 0                       | number of k8s masters to create in AD3
k8sWorkerAd1Count                   | 1                       | number of k8s workers to create in AD1
k8sWorkerAd2Count                   | 0                       | number of k8s workers to create in AD2
k8sWorkerAd3Count                   | 0                       | number of k8s workers to create in AD3
etcdAd1Count                        | 1                       | number of etcd nodes to create in AD1
etcdAd2Count                        | 0                       | number of etcd nodes to create in AD2
etcdAd3Count                        | 0                       | number of etcd nodes to create in AD3
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

#### Network
name                                | default                 | description
------------------------------------|-------------------------|------------
flannel_network_cidr                | 10.99.0.0/16            | A CIDR notation IP range to use for flannel
etcd_cluster_ingress                | 10.0.0.0/16 (VCN only)  | A CIDR notation IP range that is allowed to access the etcd cluster
etcd_ssh_ingress                    | 10.0.0.0/16 (VCN only)  | A CIDR notation IP range that is allowed to SSH to etcd nodes
master_ssh_ingress                  | 10.0.0.0/16 (VCN only)  | A CIDR notation IP range that is allowed to access the master(s)
master_https_ingress                | 10.0.0.0/16 (VCN only)  | A CIDR notation IP range that is allowed to access the HTTPs port on the master(s)
worker_ssh_ingress                  | 10.0.0.0/16 (VCN only)  | A CIDR notation IP range that is allowed to SSH to worker(s)
worker_nodeport_ingress             | 10.0.0.0/16 (VCN only)  | A CIDR notation IP range that is allowed to access NodePorts (30000-32767) on the worker(s)

#### Software Versions Installed on OCI Instances
name                                | default            | description
------------------------------------|--------------------|------------
docker_ver                          | 17.03.1            | Version of Docker to install
etcd_ver                            | v3.2.2             | Version of etcd to install
flannel_ver                         | v0.7.1             | Version of Flannel to install
k8s_ver                             | 1.7.4              | Version of K8s to install (master and workers)
k8s_dns_ver                         | 1.14.2             | Version of Kube DNS to install
k8s_dashboard_ver                   | 1.6.3              | Version of Kubernetes dashboard to install
instance_os_ver                     | 7.4                | Version of OEL operating system

#### Other
name                                | default                 | description
------------------------------------|-------------------------|------------
label_prefix                        | ""                      | Unique identifier to prefix to OCI resources


### Examples

#### Deploying a new cluster

Override any of the above input variables in your terraform.tfvars and run the plan and apply commands:

```bash
# verify what will change
$ terraform plan

# scale workers
$ terraform apply
```

#### Scaling k8s workers (in or out) using terraform apply

To scale workers in or out, adjust the `k8sWorkerAd1Count`, `k8sWorkerAd2Count`, or `k8sWorkerAd3Count` input 
variables in terraform.tfvars and run the plan and apply commands:

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

To scale the masters in or out, adjust the `k8sMasterAd1Count`, `k8sMasterAd2Count`, or `k8sMasterAd3Count` input variables in terraform.tfvars and run the plan and apply commands:

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


## Known issues and limitations
* Unsupported: scaling or replacing etcd members in or out after the initial deployment
* Unsupported: creating a service with `--type=LoadBalancer`

## Contributing

This project is open source. Oracle appreciates any contributions that are made by the open source community.

See [CONTRIBUTING](CONTRIBUTING.md) for details.

## Installed on OCI Instances

* Oracle Linux Enterprise (7.4)
* etcd - (default v3.2.2)
* flannel - (default v0.7.1)
* docker - (default 17.03.1.ce)
* apt-transport-https - (default 1.2.20)
* kubernetes - (default v1.7.4)
  * master(s) (`kube-apiserver`, `kube-controller-manager`, `kube-scheduler`, `kubernetes-cni`, `kubectl`)
  * worker(s) (`kubelet`, `kube-proxy`, `kubernetes-cni`, `kubectl`)
  * cluster add-ons: (`dashboard`, `kube-DNS`)



