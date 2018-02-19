# Gitlab Build Docker Image

This is the Docker image that this repo uses for Gitlab CI.  Its build/push is not hooked
into any automated process - that is done manually whenever needed (which should be a rare
thing).

Log into Docker registry with a user capable of pushing to the /skeppare namespace

```
docker login --username agent wcr.io
# Password is a secret!
```

Build the image, for example using 0.1 as the tag:

```
export TAG=0.1
docker build -t wcr.io/odxsre/k8s-terraform-ansible-gitlab:$TAG .
```

Push the image:

```
docker push wcr.io/odxsre/k8s-terraform-ansible-gitlab:$TAG
```

Reference the image in .gitlab-ci.yml:

```
image: wcr.io/odxsre/k8s-terraform-ansible-gitlab:0.1
```
