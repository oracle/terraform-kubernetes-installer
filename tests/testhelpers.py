#!/usr/bin/env python

import helpers
import json
import re

#
# Generally useful routines across integration tests
#

def kubectl(action, kubeconfig, exit_on_error=True, verbose=True, silent=False):
    (stdout, _, returncode) = helpers.run_command('kubectl --kubeconfig %s %s' % (kubeconfig, action),
                                                  verbose=verbose, silent=silent, verify_return_code=True)
    return stdout

def get_k8s_pods(kubeconfig, regex=None, phase=None):
    stdout = kubectl('get pods -o json', kubeconfig=kubeconfig, verbose=False, silent=True)
    podsJSON = json.loads(stdout)
    podNameList = []
    for podJSON in podsJSON["items"]:
        include = True
        if phase != None:
            include = include and podJSON["status"]["phase"] == phase

        podName = podJSON['metadata']['name'].encode('UTF8')
        if regex != None:
            pattern = re.compile(regex)
            include = include and pattern.match(podName)
        if include:
            podNameList.append(podName)
    return podNameList

def get_k8s_nodes(kubeconfig):
    stdout = kubectl('get nodes -o json', kubeconfig=kubeconfig, verbose=False, silent=True)
    nodesJSON = json.loads(stdout)
    nodeNameList = []
    for podJSON in nodesJSON["items"]:
        nodeNameList.append(podJSON['metadata']['name'].encode('UTF8'))
    return nodeNameList


