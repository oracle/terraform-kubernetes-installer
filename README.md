# Kubernetes Setup with Terraform and Ansible

This project sets up a Kubernetes cluster using Terraform and Ansible.  It addresses 
[this](https://github.com/oracle/terraform-kubernetes-installer/issues/152) tracking issue.

## Status

### Current Branch Status

This branch is currently fairly robust and contains: 
- The full project structure to stand up a working Kubernetes cluster with polished Terraform and Ansible code.
- Terraform code based on the latest TF installer code, pruned down to remove software configuration.
- Working driver scripts for creating environments and managing them via Ansible.
- Most parameters from the TF installer exposed via the driver script.
- Working integration tests deploy and verify a multi-service app.
- Working Gitlab pipeline which stands up an environment and runs integration tests.

### Further Work Needed to Reach Full Parity with TF Installer
- Installation of K8S OCI flex volume and ingress controller and related config parameters to create_env.py.
- (worker|master|etcd)_docker_* configuration parameters to create_env.py and related Ansible config code.
- Need to add Nginx installation on worker nodes (for communication with masters) and on master nodes (for communication with etcds).
- Get private cluster setup working, via a bastion when deploying Ansible.
- Sync with latest tests for TF installer project (temporarily moved under `./others-orig`).
- Update docs (temporarily moved under `./others-orig`) to sync with the new workflow.  General usage of the new
driver script is currently documented under `./docs/usage.md`.
- Convert Gitlab CI pipelines to Wercker pipelines.

### Further Improvements
Other improvements that could be made, but may not be strictly required to merge this branch:

- CI test scenarios covering more permutations of cluster setup options.  
- More consistent naming of parameters to create_env.py.  Parameter names are based on parameters from 
the current TF installer, but these could be made more consistent in general (for example, we have params
starting with "k8s_worker" and others starting with "worker").
- Create_env user interface could be made slicker if the user is prompted for certain parameters 
_conditionally_.  For example, for master LB shape only when master LB specified.   
- Remove the few remaining cloud-init bits (such as for mounting block volumes), moving these to Ansible as well.
- Remove the need for Terragrunt completely.

### Future Work

- Investigate using Ansible code from [kubespray](https://github.com/kubernetes-incubator/kubespray) to replace
our current Ansible code under `./roles`.  The rest of the project structure could remain intact, and if 
kubespray is compatible with OCI and OEL, we'd be essentially just swapping our current Ansible with kubespray.

## Repository Structure

* Ansible-related:
  * **roles** - Ansible roles.
  * **vars** - Ansible variables.
* Terraform-related:
  * **identity** - Terraform provider.
  * **instances** - Terraform compute instances.
  * **network** - Terraform network - VCNs and load balancers.
  * **tls** - Terraform key and cert generation.
* **envs** - Contains Terraform state and Ansible custom variables for all both managed (long-lived) and unmanaged
(ephemeral) environments:
  * Managed environments are checked into Git under `./envs` and are called `dev`, `integ`, or `prod`.  
  * Unmanaged environments are also placed under `./envs`, can be called anything else, and are not checked into Git. 
  * Notice how there are no Terraform config files in any of the live directories. Instead, a `terraform.tfvars` 
  file points up to the project root directory, which has the actual Terraform config.
* **images** - Custom Docker images used by this project.
* **library** - Custom Ansible tasks.
* **scripts** - Scripts to create and manage environments.
* **tests** - Integration tests.

## [Using This Repo](docs/usage.md)

## [CI/CD](docs/ci-cd.md)

## [Scripts](docs/scripts.md)

## [Integration Tests](tests/README.md)

## [Terraform References](docs/terraform.md)

## [Ansible References](docs/ansible.md)
