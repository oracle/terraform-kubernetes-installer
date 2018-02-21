# Terraform References

Usually, you'll be dealing with the helper scripts under `./scripts` to manage your environments, in which case
you won't need to interact with Terraform/Terragrunt directly.  But for whenever you do:

## Determine Details of the Deployed Environment

With a deployed environment, use ```terragrunt output``` to determine various details of interest:

Instance SSH key:

```
terragrunt output -state `pwd`/terraform.tfstate ssh_private_key
```

Instance IPs:

```
terragrunt output -state `pwd`/terraform.tfstate k8s_master_instance_public_ip
terragrunt output -state `pwd`/terraform.tfstate k8s_worker_instance_public_ip
```

VCN ID:

```
terragrunt output -state `pwd`/terraform.tfstate vcn_id
```



