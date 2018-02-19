# Terraform Kubernetes Installer for OCI Tests

## About

The Terraform Kubernetes Installer for OCI Tests provides a set of tests including:

- Terraform static config validation
- Cluster Creation Tests

Tests can be run locally and are are run against **every** commit to the main branch by default. Successful test results are also required before merging PRs into the main branch, although this is not currently automatic.

## Running Tests Locally on the CLI (in your own tenancy)

#### Prerequisites

- Set up the general prerequisites as defined [here](../README.md#Prerequisites)
- Install [Python](https://www.python.org/downloads) 2.7 or later
- Install required Python packages (below)
- Create a _terraform.tfvars_ file in the project root that specifies your the required keys and OCIDs for your tenancy, user, and compartment

```bash
# Install required Python packages
$ pip install -r requirements.txt
```

```bash
# start from the included example
$ cp terraform.example.tfvars terraform.tfvars
# specify private_key_path, fingerprint, tenancy_ocid, compartment_ocid, user_ocid, and region.
```

```bash
$ python2.7 ./create/runner.py
```

## Running Tests Locally using the Wercker CLI (in your own tenancy)

#### Prerequisites

- Install [Docker](https://docs.docker.com/engine/installation/)
- Provide Terraform the value of the required keys and OCIDs in the container through environment variables prefixed with `X_TF_VAR`:

```bash
$ cat /tmp/bmcs_api_key.pem | pbcopy
$ export X_TF_VAR_private_key=`pbpaste`
$ export X_TF_VAR_fingerprint=...
$ export X_TF_VAR_tenancy_ocid=ocid1.tenancy.oci...
$ export X_TF_VAR_compartment_ocid=ocid1.compartment.oc1...
$ export X_TF_VAR_user_ocid=ocid1.user.oc1...
$ export X_TF_VAR_region=...
$ cat /tmp/cloud_controller_bmcs_api_key.pem | pbcopy
$ export X_TF_VAR_cloud_controller_user_ocid=ocid1.user.oc1...
$ export X_TF_VAR_cloud_controller_user_fingerprint=...
$ export X_TF_VAR_cloud_controller_user_private_key=`pbpaste`
```

```bash
$ wercker build
$ wercker deploy
```

### Notes

- By default, the tests will create a series of clusters with Terraform, verify them, then destroy them
- The tests use their own _cluster_ configuration (instance shapes, etc) defined in resources/*.tfvars

