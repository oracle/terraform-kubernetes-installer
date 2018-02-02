# Example Installer Operations

## Deploying a new cluster using terraform apply

Override any of the above input variables in your terraform.vars and run the plan and apply commands:

```bash
# verify what will change
$ terraform plan 

# scale workers
$ terraform apply
```

## Scaling k8s workers (in or out) using terraform apply

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

## Scaling k8s masters (in or out) using terraform apply 

To scale the masters in or out, adjust the `k8sMasterAd1Count`, `k8sMasterAd2Count`, or `k8sMasterAd3Count` input variables in terraform.vars and run the plan and apply commands:

```bash
# verify changes
$ terraform plan

# scale master nodes
$ terraform apply
```

Similar to the initial deployment, you will need to wait for the node initialization to finish asynchronously.

## Scaling etcd nodes (in or out) using terraform apply

Scaling the etcd nodes in or out after the initial deployment is not currently supported. Terminating all the nodes in the etcd cluster will result in data loss.

## Replacing worker nodes using terraform taint 

We can use `terraform taint` to worker instances in a particular AD as "tainted", which will cause
 them to be drained, destroyed, and recreated on the next apply. This can be a useful strategy for reverting local changes or 
 regenerating a misbehaving worker.

```bash
# taint all workers in a particular AD
terraform taint -module=instances-k8sworker-ad1 oci_core_instance.TFInstanceK8sWorker
# optionally taint workers in AD2 and AD3 or do so in a subsequent apply
# terraform taint -module=instances-k8sworker-ad2 oci_core_instance.TFInstanceK8sWorker
# terraform taint -module=instances-k8sworker-ad3 oci_core_instance.TFInstanceK8sWorker

# preview changes
$ terraform plan

# drain and replace workers
$ terraform apply
```

When you are ready to make the new worker node schedulable again, use `kubectl uncordon` to undo the `kubectl drain`. 

## Replacing masters using terraform taint

We can also use `terraform taint` to master instances in a particular AD as "tainted", which will cause
 them to be destroyed and recreated on the next apply. This can be a useful strategy for reverting local 
 changes or regenerating a misbehaving master.

```bash
# taint all masters in a particular AD
terraform taint -module=instances-k8smaster-ad1 oci_core_instance.TFInstanceK8sMaster
# optionally taint masters in AD2 and AD3 or do so in a subsequent apply
# terraform taint -module=instances-k8smaster-ad2 oci_core_instance.TFInstanceK8sMaster
# terraform taint -module=instances-k8smaster-ad3 oci_core_instance.TFInstanceK8sMaster

# preview changes
$ terraform plan 

# replace workers
$ terraform apply 
```

## Upgrading Kubernetes Version

There are a few ways of moving to a new version of Kubernetes in your cluster.

The easiest way to upgrade to a new Kubernetes version is to use the scripts to do a fresh cluster install using an updated `k8s_ver` inpput variable. The downside with this option is that the new cluster will not have your existing cluster state and deployments.

The other options involve using the `k8s_ver` input variable to _replace_ master and worker instances in your _existing_ cluster. We can replace master and worker instances in the cluster since Kubernetes masters and workers are stateless. This option can either be done all at once or incrementally.

#### Option 1: Do a clean install (easiest overall approach)

Set the `k8s_ver` and follow the original instructions in the [README](../README.md) do install a new cluster. The `label_prefix` variable is useful for installing multiple clusters in a compartment.

#### Option 2: Upgrade cluster all at once (easiest upgrade)

The example `terraform apply` command below will destroy then re-create all master and worker instances using as much parallelism as possible. It's the easiest and quickest upgrade scenario, but will result in some downtime for the workers and masters while they are being re-created. The single example `terraform apply` below will:

1. drain, destroy all worker nodes
2. destroy all master nodes
3. destroy all master load-balancer backends that point to old master instances
4. re-create master instances using Kubernetes 1.7.5
5. re-create worker nodes using Kubernetes 1.7.5
6. re-create master load-balancer backends to point to new master node instances

```bash
# preview upgrade/replace
$ terraform plan -var k8s_ver=1.7.5

# perform upgrade/replace
$ terraform apply -var k8s_ver=1.7.5
```

When you are ready to make the new 1.7.5 worker node schedulable, use `kubectl uncordon`. 

#### Option 3: Upgrade cluster instances incrementally (most complicated, most control over roll-out)

##### First, upgrade master nodes by AD

If you would rather update the cluster incrementally, we start by upgrading the master nodes in each AD. In this scenario, each `terraform apply` will:

1. destroy all master instances in a particular AD
2. destroy all master load-balancer backends that point to deleted master instances
3. re-create master instances in the AD using Kubernetes 1.7.5
4. re-create master load-balancer backends to point to new master node instances

For example, here is the command to upgrade all the master instances in AD1:

```bash
# preview upgrade of all masters and their LB backends in AD1
$ terraform plan -var k8s_ver=1.7.5 -target=module.instances-k8smaster-ad1 -target=module.k8smaster-public-lb

# perform upgrade/replace masters
$ terraform apply -var k8s_ver=1.7.5 -target=module.instances-k8smaster-ad1 -target=module.k8smaster-public-lb
```

Be sure to repeat this command for each AD you have masters on.

##### Next, upgrade worker nodes by AD

After upgrading all the master nodes, we upgrade the worker nodes in each AD. Each `terraform apply` will:

1. drain all worker nodes in a particular AD to your nodes in AD2 and AD3
2. destroy all worker nodes in a particular AD
3. re-create worker nodes in a particular AD using Kubernetes 1.7.5

For example, here is the command to upgrade the master instances in AD1:

```bash
# preview upgrade of all workers in a particular AD to K8s
$ terraform plan -var k8s_ver=1.7.5 -target=module.instances-k8sworker-ad1

# perform upgrade/replace workers
$ terraform apply -var k8s_ver=1.7.5 -target=module.instances-k8sworker-ad1
```

Like before, repeat `terraform apply` on each AD you have workers on. Note that if you have more than one worker in an AD, you can upgrade worker nodes individually using the subscript operator e.g. 

```bash
# preview upgrade of a single worker in a particular AD to K8s 1.7.5
$ terraform plan -var k8s_ver=1.7.5 -target=module.instances-k8smaster-ad1.oci_core_instance.TFInstanceK8sMaster[1]

# perform upgrade/replace of worker
$ terraform apply -var k8s_ver=1.7.5 -target=module.instances-k8sworker-ad1
```

When you are ready to make the new 1.7.5 worker node schedulable, use `kubectl uncordon`. 

## Replacing etcd cluster members using terraform taint

Replacing etcd cluster members after the initial deployment is not currently supported.

## Deploying a GPU-enabled cluster

See [deploying GPU-enabled worker nodes](./gpu-workers.md) for details.

## Deleting a cluster using terraform destroy

Don't forget to delete any OCI Load Balancers that were created by the [Cloud Controller Manager](https://github.com/oracle/oci-cloud-controller-manager) for services with `--type=LoadBalancer` by running `kubectl delete svc` before trying to destroy the cluster using Terraform.

```bash
$ terraform destroy
```