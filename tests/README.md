# Integration Tests

This directory contains our Sauron project's integration tests.  These are meant to verify the functionalilty of a
given Sauron instance.  General guidelines for integration tests:
* These are not meant to be include functional tests for each individual component (for example Prometheus, Cirith, etc).
We assume that the various components functionally work by the time they are integrated with the Sauron repo.  Rather,
our goal here is to verify that:
  * The various components are basically working.
  * Our configurations of the components are correct. 
  * The connections between those components are correct.
* They should be fairly quick, and run within a few minutes.
* Our health check (./scripts/health.py) is a subset of these integration tets. 
* They may make config changes to the Sauron instance (for example, via our API), to verify what they need to verify.
In contrast, our health check may *not* make configuration (or any other disruptive) changes.
* For this reason, we can freely run our _health check_ against any live customer environment.  But _integration 
tests_ should only be run against environments whose purpose is exclusively for testing.

## Prerequisites
- Install [Python](https://www.python.org/downloads) 2.7 or later
- Deploy or reference an environment as described in the [project docs](../README.md)
- Generate Ansible hosts for the environment as described [here](../ansible/README.md#running-ansible)
- Install required Python packages:

```
pip install -r requirements.txt

```
- Set environment:

```
source env.sh
```

## Running Integration Tests

Run all tests:
```
python ./integration_tests.py <path_to_environment_health_file>
```

Integration tests can also be run before and after an upgrade, such that the tests load data into a Sauron
instance before an upgrade, and verify that the data is still present after the upgrade.

Run tests _Before_ upgrade, specifying some unique runid:
```
python ./integration_tests.py --phase before --runid myrunid123 <path_to_environment_health_file>
```

Run tests _After_ upgrade, specifying the same runid provided to the Before tests:
```
python ./integration_tests.py --phase after --runid myrunid123 <path_to_environment_health_file>
```