# Example Application Deployment

The following example walks through running a simple Nginx web server that leverages both the Cloud Controller Manager and Flexvolume Driver plugins through Kubernetes Services, Persistent Volumes, and Persistent Volume Claims.

### Create an dynamic OCI Block Volume using a Kubernetes PersistentVolumeClaim

We'll start by creating a [PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) (PVC). The cluster is integrated with the OCI [Flexvolume Driver](https://github.com/oracle/oci-flexvolume-driver). As a result, creating a PVC will result in a block storage volume to (dynamically) be created in your tenancy.

Note that the matchLabels should contain the Availability Domain (AD) you want to provision a volume in, which should match the zone of at least one of your worker nodes:

```bash
$ kubectl describe nodes | grep zone
                    failure-domain.beta.kubernetes.io/zone=US-ASHBURN-AD-1
                    failure-domain.beta.kubernetes.io/zone=US-ASHBURN-AD-2
```

```bash
$ cat nginx-pvc.yaml

kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: nginx-volume
spec:
  storageClassName: "oci"
  selector:
    matchLabels:
      oci-availability-domain: "US-ASHBURN-AD-1"
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
```

To add the PersistentVolumeClaim, run the following:

```bash
$ kubectl apply -f nginx-pvc.yaml
```

After applying the PVC, you should see a block storage volume available in your OCI tenancy.

```bash
$ kubectl  get pv,pvc
```

### Create a Kubernetes Deployment that references the PVC

Now you have a PVC, you can create a Kubernetes deployment that will consume the storage:

```bash
$ cat nginx-deployment.yaml

apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 2
  template:
    metadata:
      labels:
        name: nginx
    spec:
      containers:
        - name: nginx
          image: nginx
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 80
          volumeMounts:
            - name: nginx-storage
              mountPath: "/usr/share/nginx/html"
      volumes:
      - name: nginx-storage
        persistentVolumeClaim:
          claimName: nginx-volume
```

To run the deployment, run the following:

```bash
$ kubectl apply -f nginx-deployment.yaml
```

After applying the change, your pods should be scheduled on nodes running in the same AD of your volume and all have access to the shared volume:

```
$ kubectl get pods -o wide
NAME                     READY     STATUS    RESTARTS   AGE       IP           NODE
nginx-r1   1/1       Running   0          35s       10.99.46.4   k8s-worker-ad1-0.k8sworkerad1.k8soci.oraclevcn.com
nginx-r2   1/1       Running   0          35s       10.99.46.5   k8s-worker-ad1-0.k8sworkerad1.k8soci.oraclevcn.com
```

```
$ kubectl exec nginx-r1 touch /usr/share/nginx/html/test
```

```
$ kubectl exec nginx-r2 ls  /usr/share/nginx/html
test
lost+found
```

### Expose the app using the Cloud Controller Manager

The cluster is integrated with the OCI [Cloud Controller Manager](https://github.com/oracle/oci-cloud-controller-manager) (CCM). As a result, creating a service of type `--type=LoadBalancer` will expose the pods to the Internet using an OCI Load Balancer.

```bash
$ kubectl expose deployment nginx --port=80 --type=LoadBalancer
```

List service to get the external IP address (OCI LoadBalancer) of your exposed service. Note, the IP will be listed as `<pending>` while the load balancer is being provisioned:

```bash
$ kubectl get service nginx
```

Access the Nginx service

```
open http://<EXTERNAL-IP>:80
```

### Clean up

Clean up the container, OCI Load Balancer, and Block Volume by deleting the deployment, service, and persistent volume claim:

```bash
$ kubectl delete service nginx
```

```bash
$ kubectl delete -f nginx-deployment.yaml
```

```bash
$ kubectl delete -f nginx-pvc.yaml
```
