#!/usr/bin/env python

#
# All integration tests.  Optionally, these tests can be executed with the --phase parameter, which
# allow them to load data _before_ an upgrade operation and then verify it _after_ the upgrade.
#

import argparse
import traceback
import health
import helpers
import testhelpers
import random, string
import json
import os
import sys
import requests
import time

TESTS_DIR = os.path.abspath(os.path.dirname(__file__))
logger = helpers.setup_logging('integration_tests.log')
helpers.logger = logger
PHASE_BEFORE = "before"
PHASE_AFTER = "after"

def get_random_id():
    return ''.join([random.choice(string.lowercase) for i in xrange(20)])

def execute_before_phase(phase):
    return phase is None or phase == PHASE_BEFORE

def execute_after_phase(phase):
    return phase is None or phase == PHASE_AFTER

def verify_status_code(url, expected_status_code):
    response = requests.get(url, timeout=5)
    if response.status_code != expected_status_code:
        raise Exception('Expected status code %s from %s, got %s' % (response.status_code, url, expected_status_code))

def verify_num_pods(num, kubeconfig, regex='.*', phase='Running'):
    pods_list = testhelpers.get_k8s_pods(kubeconfig, regex=regex, phase=phase)
    if len(pods_list) != num:
        raise Exception('Expected %s pods in %s phase, found %s' % (num, phase, len(pods_list)))

#
# Component-specific integration tests
#
def k8s_tests(health_config, phase, runid):
    kubeconfig = health_config['k8s']['kubeconfig']
    worker_public_address_list = health_config['k8s']['worker-address-list']

    # Health check
    logger.info('Verifying health...')
    health.test_k8s(kubeconfig)

    # Before phase: deploy 2 services that talk to each other internally and are exposed externally
    if execute_before_phase(phase):
        logger.info("Deploying hello service")
        testhelpers.kubectl('apply -f %s/resources/hello-service.yml' % TESTS_DIR, kubeconfig=kubeconfig)
        hello_pods_ready = lambda: verify_num_pods(num=15, kubeconfig=kubeconfig, regex='^hello')
        helpers.wait_until(hello_pods_ready, 180)

        # This sleep shouldn't be necessary in latest versions of k8s
        time.sleep(5)
        testhelpers.kubectl('apply -f %s/resources/frontend-service.yml' % TESTS_DIR, kubeconfig=kubeconfig)
        frontend_pods_ready = lambda: verify_num_pods(num=3, kubeconfig=kubeconfig, regex='^frontend')
        helpers.wait_until(frontend_pods_ready, 180)

        hello_service_port = testhelpers.kubectl('get svc/hello -o jsonpath={.spec.ports[0].nodePort}', kubeconfig=kubeconfig)
        logger.info('Hello service port: %s' % str(hello_service_port))
        frontend_service_port = testhelpers.kubectl('get svc/frontend -o jsonpath={.spec.ports[0].nodePort}', kubeconfig=kubeconfig)
        logger.info('Frontend service port: %s' % str(frontend_service_port))

    # After phase: verify services are pingable
    if execute_after_phase(phase):
        try:
            logger.info('Pinging hello and frontend deployments for each K8s worker')
            for worker_public_address in worker_public_address_list:
                service_address_list = ['http://%s:%s' % (worker_public_address, hello_service_port),
                                        'http://%s:%s' % (worker_public_address, frontend_service_port)]
                for service_address in service_address_list:
                    logger.info('Checking ' + service_address)
                    deployment_ready = lambda: verify_status_code(service_address, 200)
                    helpers.wait_until(deployment_ready, 180)
        finally:
            testhelpers.kubectl('delete -f %s/resources/hello-service.yml' % TESTS_DIR, kubeconfig=kubeconfig, exit_on_error=False)
            testhelpers.kubectl('delete -f %s/resources/frontend-service.yml' % TESTS_DIR, kubeconfig=kubeconfig, exit_on_error=False)

#
# Launch all integration tests
#
def integration_tests(healthfile, phase, runid):
    health_config = json.load(open(healthfile,'r'))
    logger.debug('Endpoint configuration: %s' % json.dumps(health_config))
    exceptions = []
    phase_title_string = ' ' if phase == None else ' %s ' % phase.title()

    # Kubernetes
    try:
        helpers.log('Kubernetes%sIntegration Tests' % phase_title_string, as_banner=True, bold=True)
        k8s_tests(health_config, phase, runid)
        logger.info('Success!')
    except Exception, e:
        print traceback.format_exc(e)
        exceptions.append(e)

    # Tests of other components here...

    # Collect results and present
    helpers.log('Tests Complete', as_banner=True, bold=True)
    if len(exceptions) == 0:
        logger.info('All clean!!!')
    else:
        logger.info('Tests failed due to the following Exceptions:')
        for e in exceptions:
            print traceback.format_exc(e)
        sys.exit(1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Run acceptance tests')
    parser.add_argument('healthfile', type=str, help='The location of the health.json file')
    parser.add_argument('--phase', type=str, help='Optional "phase" to test', choices=['before','after'], required=False)
    parser.add_argument('--runid', type=str, help='Optional string that will be used to uniquely identify this test run', required=False,
                        default=get_random_id())
    args = parser.parse_args()
    integration_tests(args.healthfile, args.phase, args.runid)
