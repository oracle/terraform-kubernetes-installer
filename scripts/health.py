#!/usr/bin/python

import json
import traceback
import argparse
from argparse import RawTextHelpFormatter
from helpers import setup_logging

# Global default logger
logger = setup_logging('health.log')

def test_k8s(kubeconfig):
    # TODO - add k8s general health check
    pass

def health(healthfile, logger=logger):
    # here we try to figure out who we want to monitor by looking at the passed in health file 
    # and also to other parameters passed in which may change the behavior
    endpoints = []
    try:
        logger.info("Checking with health file: %s" % healthfile)
        f = open(healthfile,"r")
        health_config = json.load(f)

        kubeconfig = health_config['k8s']['kubeconfig']
        test_k8s(kubeconfig)

        logger.info('Health Check succeeded.')
    except Exception, e:
        logger.debug("Health File: %s" % json.dumps(endpoints))
        logger.error('Failure: ' + str(e) + ", exception: " + traceback.format_exc().replace('\n', ' | '))
        raise Exception('Health Check failed.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Health Checker', formatter_class=RawTextHelpFormatter)
    parser.add_argument('healthfile', type=str, help='The location of the health.json file')
    args = parser.parse_args()
    health(args.healthfile)
