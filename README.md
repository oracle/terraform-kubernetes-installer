# Kubernetes Setup with Terraform and Ansible

[![build status](https://gitlab-odx.oracle.com/sre/k8s-terraform-ansible/badges/master/build.svg)](https://gitlab-odx.oracle.com/sre/k8s-terraform-ansible/commits/master)

This project sets up a Kubernetes cluster using Terraform and Ansible, following the pattern used in the 
[Sauron](https://gitlab-odx.oracle.com/sre/sauron) project.  A number of helper scripts are provided that tie
together Terraform and Ansible and help to manage long-lived environments.

## Project Status

This project is currently fairly robust and contains: 
- A full project structure to stand up a working Kubernetes cluster with polished Terraform and Ansible code.
- Working integration tests deploy and verify a multi-service app.
- Working Gitlab pipeline which stands up an environment and runs integration tests.
- Working helper scripts for creating environments and managing them via Ansible. 

The work that needs to be done to make this a *fully* robust project include the following:
- Add some (whatever is needed) of the flexibility offerred by the [terraform-kubernetes-installer](https://github.com/oracle/terraform-kubernetes-installer)
project, like:
  - Customizable security list rules.
  - Creating a private cluster, not reachable from the internet
- Add OCI flex volumes.
- Add OCI ingress controller.
- Add tests in the CI pipeline for
  - More permutations of k8s cluster configuration.
  - Forcing an upgrade to critical parts of the system, like Etcd or the Flannel network, while workloads are running.
  - Upgrading from the last SHA deployed in production to the current SHA, while workloads are running.
  - Using more realistic workloads in integration tests.
- Add a CD pipeline for deploying to live environments.
- Enforce specific versions of Terraform and Terragrunt.
- Various Kubernetes update scenarios should be explicitly tested (and probably do not work currently), like:
  - Any changes to master configuration, software, or scripts should trigger a restart of components such as the API
   server and kubelet.
- For internal cluster communication (i.e. from workers to masters and masters to etcds), use local Nginx for load balancing.
- Convert pipelines to Wercker.

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
