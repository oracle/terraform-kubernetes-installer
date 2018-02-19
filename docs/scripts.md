# Helper Scripts

The scripts under `./scripts` exist to help with things like encrypting/decrypting environments,
rolling out Ansible changes to live environments, and stamping out new environments.

For dealing with your own "sandbox" environment, the only _secrets_ you need to provide are your BMC 
credentials as TF_VAR environment variables, as described in the [Usage doc](./usage.md).

#### Prerequisites
Install required Python packages:

```
pip install -r ./scripts/requirements.txt
```

For dealing with any of the _managed_ environments, you will also need to know the secret ansible-vault
password (this is an SRE team secret):

```
export ANSIBLE_VAULT_PASSWORD_FILE=/tmp/vault-password
echo $VAULT_PASSWORD > /tmp/vault-password
``` 

#### Decrypt Terraform State and Certs for a Specific Env

```
python scripts/decrypt_envs.py prod-region/some-env
```

#### Restore Encrypted Terraform State and Certs for a Specific Env

```
python scripts/reencrypt_envs.py prod-region/some-env
```

#### Restore Encrypted Terraform State and Certs for a All Envs

This is often useful to wipe any changes (files decrypted) from your local Git repo.

```
python scripts/reencrypt_all_envs.py
```

#### Populate Dynamic Files for a Specific Env

This populates dynamic files (hosts file and health check JSON) for a specific environment,
including decrypting any necessary files.

```
python ./scripts/populate_env.py prod-region/some-env
```

#### Unpopulate Dynamic Files for a Specific Env

This deletes all dynamic files for a specific environment, including re-ecrypting any necessary files.

```
python ./scripts/unpopulate_env.py prod-region/some-env
```

#### Deploy Ansible for a Specific Env

This deploys Ansible for a specific environment, including populating/unpopulating dynamic files.

```
python ./scripts/ansible_deploy_env.py prod-region/some-env
```

Or with healthcheck option:
```
python ./scripts/ansible_deploy_env.py prod-region/some-env --healthcheck
```

Or with a specific tag:
```
python ./scripts/ansible_deploy_env.py prod-region/some-env --tags some-tag
```

#### Deploy Ansible for All Envs

Use this with extreme caution - it will roll out changes to all managed environments.
```
python ./scripts/ansible_deploy_all_envs.py
```

Or with healthcheck option:
```
python ./scripts/ansible_deploy_all_envs.py --healthcheck

```

Or with specific tags:
```
python ./scripts/ansible_deploy_all_envs.py --tags some-tag,some-other-tag

```

Or excluding 2 specific environments:
```
python ./scripts/ansible_deploy_all_envs.py --exclude prod-region/some-env,prod-region/some-other-env

```