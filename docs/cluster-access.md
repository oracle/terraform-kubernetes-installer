# Accessing the Cluster

## Access the cluster using kubectl, continuous build pipelines, or other clients

If you've chosen to configure a _public_ Load Balancer for your Kubernetes Master(s) (i.e. `control_plane_subnet_access=public` or 
`control_plane_subnet_access=private` _and_ `k8s_master_lb_access=public`), you can interact with your cluster using kubectl, continuous build 
pipelines, or any other client over the Internet. A working kubeconfig can be found in the ./generated folder or generated on the fly using the `kubeconfig` Terraform output variable.

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

If you've chosen to configure a strictly _private_ cluster (i.e. `control_plane_subnet_access=private` _and_ `k8s_master_lb_access=private`), 
access to the cluster will be limited to the NAT instance(s) similar to how you would use a bastion host e.g.

```bash
$ terraform plan -var public_subnet_ssh_ingress=0.0.0.0/0
$ terraform apply -var public_subnet_ssh_ingress=0.0.0.0/0
$ terraform output ssh_private_key > generated/instances_id_rsa
$ chmod 600 generated/instances_id_rsa
$ scp -i generated/instances_id_rsa generated/instances_id_rsa opc@NAT_INSTANCE_PUBLIC_IP:/home/opc/
$ ssh -i generated/instances_id_rsa opc@NAT_INSTANCE_PUBLIC_IP
nat$ ssh -i /home/opc/instances_id_rsa opc@K8SMASTER_INSTANCE_PRIVATE_IP
master$ kubectl cluster-info
master$ kubectl get nodes 
```

Note, for easier access, consider setting up an SSH tunnel between your local host and a NAT instance.

## Access the cluster using Kubernetes Dashboard

Assuming `kubectl` has access to the Kubernetes Master Load Balancer, you can use `kubectl proxy` to access the 
Dashboard:

```
kubectl proxy &
open http://localhost:8001/ui
```

## SSH into OCI Instances

If you've chosen to launch your control plane instance in _public_ subnets (i.e. `control_plane_subnet_access=public`), you can open
 access SSH access to your master nodes by adding the following to your `terraform.tfvars` file:

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

If you've chosen to launch your control plane instance in _private_ subnets (i.e. `control_plane_subnet_access=private`), you'll 
need to first SSH into a NAT instance, then to a worker, master, or etcd node:

```bash
$ terraform plan -var public_subnet_ssh_ingress=0.0.0.0/0
$ terraform apply -var public_subnet_ssh_ingress=0.0.0.0/0
$ terraform output ssh_private_key > generated/instances_id_rsa
$ chmod 600 generated/instances_id_rsa
$ terraform output nat_instance_public_ips
$ scp -i generated/instances_id_rsa generated/instances_id_rsa opc@NAT_INSTANCE_PUBLIC_IP:/home/opc/
$ ssh -i generated/instances_id_rsa opc@NAT_INSTANCE_PUBLIC_IP
nat$ ssh -i /home/opc/instances_id_rsa opc@PRIVATE_IP
```
