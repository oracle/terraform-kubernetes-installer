# Kubernetes Setup with Terraform and Ansible

[![build status](https://gitlab-odx.oracle.com/sre/k8s-terraform-ansible/badges/master/build.svg)](https://gitlab-odx.oracle.com/sre/k8s-terraform-ansible/commits/master)

This project sets up a Kubernetes cluster using Terraform and Ansible, following the pattern used in the 
[Sauron](https://gitlab-odx.oracle.com/sre/sauron) project.  A number of helper scripts are provided that tie
together Terraform and Ansible and help to manage long-lived environments.

## Project Status

This project is currently a _starting point, but contains:
- The initial project structure to stand up a working Kubernetes cluster.  Terraform code is based off of [terraform-kubernetes-installer](https://github.com/oracle/terraform-kubernetes-installer)
from a few months ago (currently minus LBs).
- Initial working integration tests deploy and verify a multi-service app.
- Working Gitlab pipeline which stands up an environment and runs integration tests.
- Working helper scripts for creating managed/unmanaged environments and managing them via Ansible. 

The work that needs to be done to make this a robust project include the following:
- Add back automatic cert generation from Joe Rosinksi's (k8s-ansible-terraform-installer branch)[https://gitlab-odx.oracle.com/sre/terraform-k8s-installer-baremetal/tree/k8s-ansible-terraform-installer]. 
- Add in refactored Ansible roles structure from Joe Rosinksi's (k8s-ansible-terraform-installer branch)[https://gitlab-odx.oracle.com/sre/terraform-k8s-installer-baremetal/tree/k8s-ansible-terraform-installer].
- Add some (whatever is needed) of the flexibility offerred by the [terraform-kubernetes-installer](https://github.com/oracle/terraform-kubernetes-installer)
project, like:
  - Putting an LB in front of the k8s master.
  - Customizable security list rules.
  - Ability to put etcd on separate nodes from master.
- Syncing up with other work from the [terraform-kubernetes-installer](https://github.com/oracle/terraform-kubernetes-installer), like:
   - Updating to the latest k8s version.
   - Updating to latest flannel version.
   - Support for OCI flex volumes.
   - Support for OCI ingress controller.
- Add tests in the CI pipeline for
  - More permutations of k8s cluster configuration.
  - Forcing an upgrade to critical parts of the system, like etcd or the flannel network, while workloads are running.
  - Upgrading from the last SHA deployed in production to the current SHA, while workloads are running.
  - Using more realistic workloads in integration tests.
- Get idempotency working (rerunning Ansible currently results in "changes"), and enable idempotency test in Gitlab CI.
- Add a CD pipeline for deploying to live environments.

## Repository Structure

* **envs** - Contains Terraform state and Ansible custom variables for all both managed (long-lived) and unmanaged
(ephemeral) environments:
  * Managed environments are checked into Git under `./envs` and are called `dev`, `integ`, or `prod`.  
  * Unmanaged environments are also placed under `./envs`, can be called anything else, and are not checked into Git. 
  * Notice how there are no Terraform config files in any of the live directories. Instead, a `terraform.tfvars` 
  file points up to the `terraform-stack/` directory which has the actual Terraform config.
* **images** - Custom Docker images used by this project.
* **library** - Custom Ansible tasks.
* **roles** - Ansible roles.
* **scripts** - Scripts to create and manage environments.
* **terraform-stack** - Terraform code.
* **tests** - Integration tests.
* **vars** - Ansible variables.

## [Using This Repo](docs/usage.md)

## [CI/CD](docs/ci-cd.md)

## [Scripts](docs/scripts.md)

## [Integration Tests](tests/README.md)

## [Terraform References](docs/terraform.md)

## [Ansible References](docs/ansible.md)
