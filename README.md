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


## Cluster Overview

Terraform is used to _provision_ the cloud infrastructure and any required local resources for the Kubernetes cluster including:

#### OCI Infrastructure

- Virtual Cloud Network (VCN) with dedicated subnets for etcd, masters, and workers in each availability domain
- Dedicated compute instances for etcd, Kubernetes master and worker nodes in each availability domain
- Public or Private TCP/SSL OCI Load Balancer to to distribute traffic to the Kubernetes Master(s)
- Private OCI Load Balancer to distribute traffic to the node(s) in the etcd cluster
- _Optional_ NAT instance for Internet-bound traffic on any private subnets
- 2048-bit SSH RSA Key-Pair for compute instances when not overridden by `ssh_private_key` and `ssh_public_key_openssh` input variabless
- Self-signed CA and TLS cluster certificates when not overridden by the input variables `ca_cert`, `ca_key`, etc.

#### Cluster Configuration

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
4.  Ensure you have [Kubectl][Kubectl] installed if you plan to interact with the cluster locally


## Quick start

### Customize the configuration

Create a _terraform.tfvars_ file in the project root that specifies your configuration.

```bash
# start from the included example
$ cp terraform.example.tfvars terraform.tfvars
```

* Set [mandatory](./docs/input-variables.md#mandatory-input-variables) OCI input variables relating to your tenancy, user, and compartment.
* Override [optional](./docs/input-variables.md#optional-input-variables) input variables to customize the default configuration

### Deploy the cluster

Initialise Terraform:

```
$ terraform init
``` 

View what Terraform plans do before actually doing it:

```
$ terraform plan
```

Use Terraform to Provision resources and stand-up k8s cluster on OCI:

```
$ terraform apply
```

### Access the cluster

The Kubernetes cluster will be running after the configuration is applied successfully and the cloud-init scripts have been given time to finish asynchronously. Typically this takes around 5 minutes after `terraform apply` and will vary depending on the overall configuration, instance counts, and shapes.

A working kubeconfig can be found in the ./generated folder or generated on the fly using the `kubeconfig` Terraform output variable.

Your network access settings determine whether your cluster is accessible from the outside. See [Accessing the Cluster](./docs/cluster-access.md) for more details.

### Scale, upgrade, or delete the cluster

Check out the [example operations](./docs/examples.md) for details on how to use Terraform to scale, upgrade, replace, or delete your cluster.

## Known issues and limitations
* Scaling or replacing etcd members in or out after the initial deployment is currently unsupported
* Creating a service with `--type=LoadBalancer` is currently unsupported
* Failover or HA configuration for NAT instance(s) is currently unsupported

## Contributing

This project is open source. Oracle appreciates any contributions that are made by the open source community.

See [CONTRIBUTING](CONTRIBUTING.md) for details.