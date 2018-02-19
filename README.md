# ODX Logging & Monitoring

[![build status](https://gitlab-odx.oracle.com/sre/sauron/badges/master/build.svg)](https://gitlab-odx.oracle.com/sre/sauron/commits/master)

This repository is the home of the Terraform code, Terraform live environment state, and Ansible code for
provisioning Logging & Monitoring stacks to be consumed by service teams.

## Repository Structure

* **envs** - Contains the Terraform configuration (and state, temporarily) and Ansible custom variables
  for all environments, both live and ephemeral.
  * Managed environments are checked into Git under `envs/dev-<region>`, `envs/integ-<region>`, and `env/prod-<region>`.
  * Unmanaged environments are also placed under `envs`, but are not checked into Git. 
  * Notice how there are no Terraform config files in any of the live directories. Instead, a `terraform.tfvars` 
  file points up to the `terraform-stack/` directory which has the actual Terraform config.
* **images** - Custom Docker images used by this project.
* **library** - Custom Ansible tasks.
* **roles** - Ansible roles.
* **scripts** - Common scripts.
* **terraform-stack** - Terraform code.
* **tests** - Integration tests.
* **vars** - Ansible variables.

## [Using This Repo](docs/usage.md)

## [Deployed Endpoints](docs/endpoints.md)

## [CI/CD](docs/ci-cd.md)

## [Scripts](docs/scripts.md)

## [Integration Tests](tests/README.md)

## [Terraform References](docs/terraform.md)

## [Ansible References](docs/ansible.md)
