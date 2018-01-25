# GPUs on Worker Nodes

Oracle Cloud Infrastructure provides GPU instance shapes and corresponding OS images that have the required drivers and libraries, which can be used to run specific workloads.

## Deploying a cluster with GPU-enabled worker nodes

To enable GPU on your worker nodes, set the GPU instance shapes and OS input variables in your in terraform.vars e.g.: `k8sWorkerShape = "BM.GPU2.2"` and `worker_ol_image_name = "Oracle-Linux-7.4-Gen2-GPU-2018.01.10-0"`.

Next, run the plan and apply commands:

```bash
# verify changes
$ terraform plan

# Note, GPU instance shapes are currently only available in the Ashburn region
$ terraform apply
```

The Kubernetes worker nodes nodes will have both GPU devices and the NVIDIA drivers pre-installed and configured. The kubelet will be pre-configured with the `Accelerators=true` option which enables the alpha.kubernetes.io/nvidia-gpu as a schedulable resource:

```
$ kubectl describe nodes
...
Capacity:
 alpha.kubernetes.io/nvidia-gpu:  2
 cpu:                             56
 memory:                          196439168Ki
 pods:                            110
```


## Assign GPU resources to pods

You can request and consume the GPUs on your worker nodes from pods by requesting `alpha.kubernetes.io/nvidia-gpu` resources as you would CPU or memory. Note that the NVIDIA and CUDA libraries that are installed on the worker needs to also be available to the pod. So, we are mounting them as volumes in these examples.

Here's a simple example pod requesting 1 GPU, and running the NVIDIA System Management Interface (nvidia-smi) command line utility to list the available GPUs and exit:

```bash
$ cat nvidia-smi.yaml

apiVersion: v1
kind: Pod
metadata:
  name: nvidia-smi
spec:
  containers:
  - image: nvidia/cuda
    name: nvidia-smi
    command: [ "nvidia-smi" ]
    resources:
      limits:
        alpha.kubernetes.io/nvidia-gpu: 1
      requests:
        alpha.kubernetes.io/nvidia-gpu: 1
    volumeMounts:
    - mountPath: /usr/bin/
      name: binaries
    - mountPath: /usr/lib64/nvidia
      name: libraries
  restartPolicy: Never
  volumes:
  - name: binaries
    hostPath:
      path: /bin/
  - name: libraries
    hostPath:
      path: /usr/lib64/nvidia
```

Deploy and print the pod logs:

```
kubectl apply -f nvidia-smi.yaml
kubectl get pods  --show-all
kubectl logs nvidia-smi
```

Here's an example of a pod requesting 2 GPUs, and importing the tensorflow GPUs and exits:

```bash
$ cat tenserflow.yaml

kind: Pod
apiVersion: v1
metadata:
  name: nvidia-tensorflow
spec:
  containers:
  - name: gpu-container
    image: tensorflow/tensorflow:latest-gpu
    imagePullPolicy: Always
    command: ["python", "-c", "import tensorflow as tf; print(tf.__version__)"]
    resources:
      requests:
        alpha.kubernetes.io/nvidia-gpu: 2
      limits:
        alpha.kubernetes.io/nvidia-gpu: 2
    volumeMounts:
    - name: libraries
      mountPath: /usr/local/nvidia/lib64
      readOnly: true
  restartPolicy: Never
  volumes:
  - name: libraries
    hostPath:
      path: /usr/lib64/nvidia
```

Deploy and print the pod logs:

```
kubectl apply -f tenserflow.yaml
kubectl get pods  --show-all
kubectl logs nvidia-tensorflow
```

## Known issues and limitations

* Scheduling GPUs in Kubernetes is still experimental, but is enabled by default in the Kubernetes Installer for OCI.
* GPU Bare Metal instance shapes are currently only available in the Ashburn region and may be limited to specific availability domains.
* The Kubernetes Installer for OCI does not support provisioning a _mix_ of GPU-enabled and non-GPU-enabled worker node instance shapes. The cluster either has _all_ or _no_ GPU-enabled workers.
