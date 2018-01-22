# GPUs on Worker Nodes

Oracle Cloud Infrastructure provides GPU instance shapes and corresponding OS images that have the required drivers, which can be used to run specific workloads.

## Deploying a cluster with GPU-enabled worker nodes

To enable GPU on your worker nodes, set the GPU instance shapes and OS input variables in your in terraform.vars e.g.: `k8sWorkerShape = "BM.GPU2.2"` and `worker_ol_image_name = "Oracle-Linux-7.4-Gen2-GPU-2017.11.15-0"`.

Next, run the plan and apply commands:

```bash
# verify changes
$ terraform plan

# Note, GPU instance shapes are currently only available in the Ashburn region
$ terraform apply
```

## Known issues and limitations

* Scheduling GPUs in Kubernetes is still experimental, but is enabled by default in the Kubernetes Installer for OCI.
* GPU Bare Metal instance shapes are currently only available in the Ashburn region and may be limited to specific availability domains.
* The Kubernetes Installer for OCI does not support provisioning a _mix_ of GPU-enabled and non-GPU-enabled worker node instance shapes. The cluster either has _all_ or _no_ GPU-enabled workers.
