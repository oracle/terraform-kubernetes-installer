# Example Operations

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

## Replacing masters using terraform taint

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

## Upgrading cluster using the k8s_ver input variable 

One way to upgrade your cluster is by incrementally changing the value of the `k8s_ver` input variable on your master and then worker nodes.

```bash
# preview upgrade of all workers in AD1 to K8s 1.7.5
$ terraform plan -var k8s_ver=1.7.5 -target=module.instances-k8sworker-ad1

# perform upgrade/replace workers
$ terraform apply -var k8s_ver=1.7.5 -target=module.instances-k8sworker-ad1
```

The above command will:

1. drain all worker nodes in AD1 to your nodes in AD2 and AD3
2. destroy all worker nodes in AD1
3. re-create worker nodes in AD1 using Kubernetes 1.7.5

If you have more than one worker in an AD, you can upgrade worker nodes individually using the subscript operator

```bash
# preview upgrade of a single worker in AD1 to K8s 1.7.5
$ terraform plan -var k8s_ver=1.7.5 -target=module.instances-k8smaster-ad1.oci_core_instance.TFInstanceK8sMaster[1]

# perform upgrade/replace of worker
$ terraform apply -var k8s_ver=1.7.5 -target=module.instances-k8sworker-ad1
```
Be sure to smoke test this approach on a stand-by cluster to weed out pitfalls and ensure our scripts are compatible 
with the version of Kubernetes you are trying to upgrade to. We have not tested other versions of Kubernetes other 
than the current default version.

## Replacing etcd cluster members using terraform taint

Replacing etcd cluster members after the initial deployment is not currently supported.

## Deleting a cluster using terraform destroy

```bash
$ terraform destroy
```
