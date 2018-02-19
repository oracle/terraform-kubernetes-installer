# Ansible References

## Specifying Backups in Unmanaged Environments

If you want your unmanaged environment to create backups, such as for testing purposes, provide 
details in the environment's `group_vars/all/all.yml` for where to create the backups, for example:

```
backup_bmc_region: "us-ashburn-1"
backup_bmc_tenancy: "ocid1.tenancy.oc1..aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
backup_bmc_user_fingerprint: "00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00"
backup_bmc_user_ocid: "ocid1.user.oc1..aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
backup_bmc_src_key_file: "files/my_api_key.pem"
```

And then deploy Ansible to the environment (let's say the environment is called my-sandbox):

```
python ./scripts/ansible_deploy_env.py my-sandbox
```

## Specifying Meta-Sauron in Unmanaged Environments

If you are trying to test dashboards and alerts that are meant for the _Meta-Sauron_ instance, you 
can turn your environment into a mini Meta-Sauron by pointing it to itself.

Provide the following in the environment's `group_vars/all/all.yml`:
```
meta_instance_username:            "<your_user>"
meta_instance_password:            "<your_password>"
meta_instance_pushgw_url:          "http://<internal_ip_of_monitoring>:19091"
meta_instance_es_host:             "<internal_ip_of_logging>"
meta_instance_es_port:             19200
meta_instance_es_protocol:         http
```
And then deploy Ansible to the environment (let's say the environment is called my-sandbox):

```
python ./scripts/ansible_deploy_env.py my-sandbox
```

## Backup and Restore
`The restore ansible scripts will ONLY restore data and NO installing will be performed. Please make sure the base system/infrastructure/applications are in place before running the restore scripts.`

### Backup location
Default OCI backup location: https://console.us-ashburn-1.oraclecloud.com/#/a/storage/objects/odx-sre/backup
```
Backup object name for monitoring node:
    /data/backup/sre-backup-<envname>.sauron.us-ashburn-1.oracledx.com/data-logging-host-<timestamp>.tgz

Backup object name for logging node:
    /data/backup/sre-backup-<envname>.sauron.us-ashburn-1.oracledx.com/data-monitoring-host-<timestamp>.tgz
````

### Manual Backup
*```Default backup_timestamp is "%Y%m%d-%H%M"```*
##### Backup both logging and monitoring nodes
```
python scripts/ansible_deploy_env.py dev-region/some-env --playbook playbooks/backup-all.yml [--extra_vars "backup_timestamp=<time_stamp>"] [--force]
```
##### Backup logging node only
```
python scripts/ansible_deploy_env.py dev-region/some-env --playbook playbooks/backup-logging.yml [--force] [--extra_vars "backup_timestamp=<time_stamp>"] [--force]
```
##### Backup monitoring node only
```
python scripts/ansible_deploy_env.py dev-region/some-env --playbook playbooks/backup-monitoring.yml [--force] [--extra_vars "backup_timestamp=<time_stamp>"] [--force]
```

### Manual Restore to same env
*```An explicit backup_timestamp must be specified to restore from.```*
##### Restore both logging and monitoring nodes
```
python scripts/ansible_deploy_env.py dev-region/some-env --playbook playbooks/restore-all.yml --extra_vars "backup_timestamp=<time_stamp>" [--force]
```
##### Restore logging node only
```
python scripts/ansible_deploy_env.py dev-region/some-env --playbook playbooks/restore-logging.yml --extra_vars "backup_timestamp=<time_stamp>" [--force]
```
##### Restore monitoring node only
```
python scripts/ansible_deploy_env.py dev-region/some-env --playbook playbooks/restore-monitoring.yml --extra_vars "backup_timestamp=<time_stamp>" [--force]
```

### Manual Restore to different env
*```When restoring backup to differrent env, alertmanager won't be overwritten, all grafana alert notifications from backup will be removed. and the current grafana admin password will not be changed.```*
##### Restore both logging and monitoring nodes
```
python scripts/ansible_deploy_env.py dev-region/some-env --playbook playbooks/restore-all.yml --extra_vars "backup_timestamp=<time_stamp> backup_domain_name=dev.other-env.sauron.us-ashburn-1.oracledx.com backup_api_user=<user> backup_api_password=<password>" [--force]
```
##### Restore logging node only
```
python scripts/ansible_deploy_env.py dev-region/some-env --playbook playbooks/restore-logging.yml --extra_vars "backup_timestamp=<time_stamp> backup_domain_name=dev.other-env.sauron.us-ashburn-1.oracledx.com backup_api_user=<user> backup_api_password=<password>" [--force]
```
##### Restore monitoring node only
```
python scripts/ansible_deploy_env.py dev-region/some-env --playbook playbooks/restore-monitoring.yml --extra_vars "backup_timestamp=<time_stamp> backup_domain_name=dev.other-env.sauron.us-ashburn-1.oracledx.com backup_api_user=<user> backup_api_password=<password>" [--force]
```
