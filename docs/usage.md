[ansible tips]: https://ansible-tips-and-tricks.readthedocs.io/en/latest/ansible/install
[terraform]: https://terraform.io
[terragrunt]: https://github.com/gruntwork-io/terragrunt
[bmcs]: https://cloud.oracle.com/en_US/bare-metal
[bmcs provider]: https://github.com/oracle/terraform-provider-baremetal/releases
[sudoers]: https://stackoverflow.com/questions/8633461/how-to-keep-environment-variables-when-using-sudo

# Using this Repo

## Prerequisites

* Download and install [Ansible][ansible tips] **2.3** or higher (`brew install ansible`)
* Download and install [Terraform][terraform] **0.10.4** or higher (`brew install terraform`)
* Download and install [Terragrunt][terragrunt]  (`brew install terragrunt`)
* Download and install [BareMetal Terraform Provider][bmcs provider] version **1.0.18**
* Create a Terraform configuration file at  `~/.terraformrc` that specifies the path to the baremetal provider:
```
    providers {
        baremetal = "<path_to_provider_binary>/terraform-provider-baremetal"
    }
```
* (macOS) Install "requests" Python Package (`sudo easy_install -U requests`)
  - if `sudo easy_install` couldn't access Internet, click [here][sudoers]

## Setting up a Unmanaged Sandbox Environment

The following script will create an "unmanaged" environment (i.e. a personal environment just for you 
that won't be checked into Git):

```
python ./scripts/create_env.py my-sandbox --unmanaged 
```

A number of parameters must be provided to this script, such as OCI tenancy/compartment/user details, 
and the admin Sauron credentials to be created for the new environment.  See the script `--help` for usage.
If not specified on the command line, the script will prompt for all required parameters.  

Additionally, a preferences file (default: `~/.sauron/config`) can be used to specify parameters.

```
python ./scripts/create_env.py my-sandbox --unmanaged --prefs /tmp/.sauron/config
```

Here is a sample of the preferences file:

```
[SAURON]
user_ocid=ocid1.user.oc1..aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
fingerprint=aa:aa:aa:aa:aa:aa:aa:aa:aa:aa:aa:aa:aa:aa:aa:aa
private_key_file=/tmp/odx-sre-api_key.pem
admin_user=myadminuser
admin_password=mystrongadminpassword
external_domain=sandbox.oracledx.com
self_signed_certs=True
tenancy_ocid=ocid1.tenancy.oc1..aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
compartment_ocid=ocid1.compartment.oc1..aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
region=us-ashburn-1
shape=VM.Standard1.2
logging_ad=1
monitoring_ad=1
```

Notes:
* If you don't care about attaching your own official certs to the environment, use 
`--self_signed_certs=True`.
* Otherwise, provide a `--certs_dir` that contains your own official certs: a .key.pem and a .pem file.

## Setting up a Managed Environment

* First, configure your ansible-vault environment. You must know the secret VAULT_PASSWORD to do this:

```
export ANSIBLE_VAULT_PASSWORD_FILE=/tmp/vault-password
echo $VAULT_PASSWORD > /tmp/vault-password
``` 

Use the `./scripts/create_env.py` script with the **--managed** option, like:

```
python ./scripts/create_env.py prod-us-ashburn-1/oke --managed 
```

Notes:
* Managed environemnts must be of the form &#60;stage&#62;/&#60;team&#62;, and the script enforces this.
* The tenancy, compartment, and node shape for managed environments is pre-set.  The script will fail
if you try to specify these for managed environments.
* The OCI user you supply here (via prompt, command line, or preferences file), must be authorized
to deploy to the official Sauron prod or dev compartment.
* After Ansible deployment is complete, the script will encrypt sensitive environment files, commit the
environment's files, create a Git branch, and instruct you to create an MR with the changes.

Upon completion of the script, you'll see a message like this:

```
Environment files have been committed to the local branch dsimone/create-prod-oke-env. Proceed by pushing this branch and creating an MR.
```

At this point, push the branch and create and MR to commit the changes to master.

Alternatively, you can choose to skip branch creation by passing in `--skip_branch`.  A new commit will still be 
created for the new environment's files, but no branch will be created.  One such use for this option is
when you are creating many managed environments in one sitting, and you want to handle branch creation yourself.

## Rolling Out Ansible Changes to Live Environments

Choose the environment under ```envs``` you wish to deploy to via Ansible.  Some examples of valid
environment names:
* dev-us-ashburn-1/sre
* prod-us-ashburn-1/sre

Let's say we are rolling out a change to an environment called "dev-region/some-env".

* First, configure your ansible-vault environment.  You must know the secret VAULT_PASSWORD to do this:
 
```
export ANSIBLE_VAULT_PASSWORD_FILE=/tmp/vault-password
echo $VAULT_PASSWORD > /tmp/vault-password
``` 
 
#### Terraform Part

**Note** - Use extreme care when running Terraform updates!!!

* Decrypt the certs for the environment:

```
python scripts/decrypt_env.py dev-region/some-env
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
python ./scripts/ansible_deploy_env.py dev-region/some-env
```

Or, to run just a specific tag, for example:

```
python ./scripts/ansible_deploy_env.py dev-region/some-env -tags elasticsearch
```
