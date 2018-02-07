[ansible tips]: https://ansible-tips-and-tricks.readthedocs.io/en/latest/ansible/install
[terraform]: https://terraform.io
[terragrunt]: https://github.com/gruntwork-io/terragrunt
[bmcs]: https://cloud.oracle.com/en_US/bare-metal
[bmcs provider]: https://github.com/oracle/terraform-provider-baremetal/releases
[sudoers]: https://stackoverflow.com/questions/8633461/how-to-keep-environment-variables-when-using-sudo

# Using this Repo

## Prerequisites

* Download and install [Ansible][ansible tips] **2.4** or higher (`brew install ansible`)
* Download and install [Terraform][terraform] **0.10.4 exactly** (`brew install terraform`)
* Download and install [Terragrunt][terragrunt] **0.13.2** or higher (`brew install terragrunt`)
* Download and install [BareMetal Terraform Provider][bmcs provider] version **1.0.18**
* Create a Terraform configuration file at  `~/.terraformrc` that specifies the path to the baremetal provider:
```
    providers {
        baremetal = "<path_to_provider_binary>/terraform-provider-baremetal"
    }
```
* (macOS) Install "requests" Python Package (`sudo easy_install -U requests`)
  - if `sudo easy_install` couldn't access Internet, click [here][sudoers]
  
## Seeding Ansible Vault

If you are forking this repo and want to use it to manage your own live environments, you'll need to:
- Generate some password, to be kept secret and shared among your development team only.
- Regenerate the `./scripts/ansible-vault-challenge.txt` file, which is used in this project's tooling before
encrypting a new managed environment:

```
export ANSIBLE_VAULT_PASSWORD_FILE=/tmp/vault-password
echo $VAULT_PASSWORD > /tmp/vault-password
echo "challenge accepted" > scripts/ansible-vault-challenge.txt
ansible-vault encrypt scripts/ansible-vault-challenge.txt
git add scripts/ansible-vault-challenge.txt
``` 

From this point on, the tooling will enforce that ANSIBLE_VAULT_PASSWORD_FILE is set and contains the correct
password, when dealing with managed environments.

## Setting up a Unmanaged Environment

The following script will create an "unmanaged" environment (i.e. a personal environment just for you 
that won't be checked into Git):

```
python ./scripts/create_env.py my-sandbox --unmanaged 
```

A number of parameters must be provided to this script, such as OCI tenancy/compartment/user details. 
See the script `--help` for usage. If not specified on the command line, the script will prompt for all required parameters.  

Additionally, a preferences file (default: `~/.k8s/config`) can be used to specify parameters.

```
python ./scripts/create_env.py my-sandbox --unmanaged --prefs /tmp/.k8s/config
```

Here is a sample of the preferences file:

```
[K8S]
user_ocid=ocid1.user.oc1..aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
fingerprint=aa:aa:aa:aa:aa:aa:aa:aa:aa:aa:aa:aa:aa:aa:aa:aa
private_key_file=/tmp/odx-sre-api_key.pem
tenancy_ocid=ocid1.tenancy.oc1..aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
compartment_ocid=ocid1.compartment.oc1..aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
region=us-ashburn-1
k8s_master_shape=VM.Standard1.2
k8s_worker_shape=VM.Standard1.2
k8s_master_ad1_count=1
k8s_master_ad2_count=0
k8s_master_ad3_count=0
k8s_worker_ad1_count=1
k8s_worker_ad2_count=0
k8s_worker_ad3_count=0
```

## Setting up a Managed Environment

* First, configure your ansible-vault environment. You'll need to know the secret VAULT_PASSWORD to do this:

```
export ANSIBLE_VAULT_PASSWORD_FILE=/tmp/vault-password
echo $VAULT_PASSWORD > /tmp/vault-password
``` 

Use the `./scripts/create_env.py` script with the **--managed** option, like:

```
python ./scripts/create_env.py prod --managed 
```

Notes:
* After Ansible deployment is complete, the script will encrypt sensitive environment files, commit the
environment's files, create a Git branch, and instruct you to create an MR with the changes.

Upon completion of the script, you'll see a message like this:

```
Environment files have been committed to the local branch dsimone/create-prod-env. Proceed by pushing this branch and creating an MR.
```

At this point, push the branch and create and MR to commit the changes to master.

Alternatively, you can choose to skip branch creation by passing in `--skip_branch`.  A new commit will still be 
created for the new environment's files, but no branch will be created.  One such use for this option is
when you are creating many managed environments in one sitting, and you want to handle branch creation yourself.

## Rolling Out Ansible Changes to Managed Environments

Let's say we are rolling out a change to the `prod` environment:

* First, configure your ansible-vault environment.  You'll need to know the secret VAULT_PASSWORD to do this:
 
```
export ANSIBLE_VAULT_PASSWORD_FILE=/tmp/vault-password
echo $VAULT_PASSWORD > /tmp/vault-password
``` 

#### Terraform Part

**Note** - Use extreme care when running Terraform updates!!!

* Decrypt the certs for the environment:

```
python scripts/decrypt_env.py some-env
```

* `cd envs/sandbox`
* Run ```terragrunt plan -state `pwd`/terraform.tfstate``` to see the changes you're about to apply.
* If the plan looks good, run:

```
terragrunt apply -state=`pwd`/terraform.tfstate
```

#### Ansible Part

* The following takes care of decrypting the environment's files, dynamically populating the Ansible 
inventory and SSH private key, and deploying via Ansible:

```
python ./scripts/ansible_deploy_env.py some-env
```

Or, to run just a specific tag, for example:

```
python ./scripts/ansible_deploy_env.py some-env -tags foo
```
