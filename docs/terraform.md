# Terraform References

## Determine Details of the Deployed Environment

With a deployed environment, use ```terragrunt output``` to determine various details of interest:

Instance SSH key:

```
terragrunt output -state `pwd`/terraform.tfstate ssh_private_key
```

Instance IPs:

```
terragrunt output -state `pwd`/terraform.tfstate logging_instance_public_ip
terragrunt output -state `pwd`/terraform.tfstate monitoring_instance_public_ip
```

VCN ID:

```
terragrunt output -state `pwd`/terraform.tfstate vcn_id
```



