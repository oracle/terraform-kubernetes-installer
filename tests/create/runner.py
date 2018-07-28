#!/usr/bin/env python2.7

import argparse
import json
import os
import select
import subprocess
import sys
import time
import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
import traceback

TEST_ROOT_DIR = os.path.abspath(os.path.dirname(os.path.abspath(__file__)) + "/..")
ROOT_DIR = os.path.abspath(TEST_ROOT_DIR + "/..")
TEST_NAME = "createtests"

def _banner(as_banner, bold):
    if as_banner:
        if bold:
            print "********************************************************"
        else:
            print "--------------------------------------------------------"


def _test_log(string):
    # Extra precautionary measure
    if "ocid1.compartment" not in string and "ssh_authorized_keys" not in string:
        print string
    else:
        first = string.split(":")
        print first[0] + ":************************<omitted>************************"


def _log(string, as_banner=False, bold=False):
    _banner(as_banner, bold)
    print string
    _banner(as_banner, bold)


def _process_stream(stream, read_fds, global_buf, line_buf):
    char = stream.read(1)
    if char == '':
        read_fds.remove(stream)
    global_buf.append(char)
    line_buf.append(char)
    if char == '\n':
        _test_log(''.join(line_buf).rstrip('\n'))
        line_buf = []
    return line_buf


def _poll(stdout, stderr):
    stdoutbuf = []
    stdoutbuf_line = []
    stderrbuf = []
    stderrbuf_line = []
    read_fds = [stdout, stderr]
    x_fds = [stdout, stderr]
    while read_fds:
        rlist, _, _ = select.select(read_fds, [], x_fds)
        if rlist:
            for stream in rlist:
                if stream == stdout:
                    stdoutbuf_line = _process_stream(stream, read_fds, stdoutbuf, stdoutbuf_line)
                if stream == stderr:
                    stderrbuf_line = _process_stream(stream, read_fds, stderrbuf, stderrbuf_line)
    return (''.join(stdoutbuf), ''.join(stderrbuf))


def _run_command(cmd, cwd):
    process = subprocess.Popen(cmd,
                               stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE,
                               shell=True, cwd=cwd)
    (stdout, stderr) = _poll(process.stdout, process.stderr)
    returncode = process.wait()
    if returncode != 0:
        _log("    stdout: " + stdout)
        _log("    stderr: " + stderr)
        _log("    result: " + str(returncode))
    return (stdout, stderr, returncode)


def _wait_until(predicate, timeoutSeconds, delaySeconds=0.25, *args, **kwargs):
    """
    Calls a predicate repeatedly, up until a specified number of seconds,
    until it returns true, throws an error if true is never returned by the predicate.
    :param predicate: the predicate to evaluate
    :param timeoutSeconds: seconds before timing out
    :param delaySeconds: seconds between evaluations
    """
    mustend = time.time() + timeoutSeconds
    while time.time() < mustend:
        try:
            if predicate(*args, **kwargs): return
        except Exception:
            pass
        time.sleep(delaySeconds)

    print("Condition not met within " + str(timeoutSeconds))
    raise Exception("Condition not met within " + str(timeoutSeconds))


def _utf_encode_list(list):
    return [s.encode("UTF8") for s in list]


def _terraform(action, vars=None):
    if vars == None:
        vars = ""
    else:
        vars += " "
    (stdout, _, returncode) = _run_command("terraform " + action + " " + vars, ROOT_DIR)
    if returncode != 0:
        _log("Error running terraform")
        raise Exception("Error running terraform")
    return stdout


def _check_env():
    pass


def _handle_args():

    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
description:
This script allows for automated testing of Terraform Kubernetes 
installation configurations in the ./tests/resources/configs/ 
directory or by a custom terfaform.tfvars file. In any event, 
after applying the configuration(s), the script performs some 
basic tests on the K8s cluster including that the worker nodes are 
healthy and that a simple application can be deployed and accessed 
(assuming control_plane_subnet_access is public). After the 
validations are complete, it (optionally) tears down the configuration.

examples:
- ./create/runner.py

    Applies, tests, and tears down _all_ the example K8s cluster configurations defined in ./tests/resources/configs/*.tfvars

- ./create/runner.py --tfvars-file /Users/you/configs/one-off-cluster.tfvars

    Applies, tests, and tears down the K8s cluster configuration defined by the custom one-off-cluster.tfvars

- ./create/runner.py --no-destroy --tfvars-file /Users/you/configs/one-off-cluster.tfvars

    Applies and tests, the K8s cluster configuration defined in one-off-cluster.tfvars, but does not destroy it when complete
"""
    )

    parser.add_argument('--no-create',
                        help='Disable the creation of the test infrastructure',
                        action='store_true',
                        default=False)
    parser.add_argument('--no-destroy',
                        help='If we are creating the test infrastructure, then leave it up',
                        action='store_true',
                        default=False)
    parser.add_argument('--tfvars-file',
                        dest='tfvars_file',
                        help='Use a custom .tfvars file for tests (default is all .tfvars in resources/configs/)',
                        metavar='')
    args = parser.parse_args()
    return args


def _kubectl(action, exit_on_error=True):
    (stdout, _, returncode) = _run_command("kubectl --kubeconfig " + ROOT_DIR + "/generated/kubeconfig" + " " + action,
                                           ROOT_DIR)
    if exit_on_error and returncode != 0:
        _log("Error running kubectl")
        sys.exit(1)
    return stdout


def _verifyConfig(tfvars_file, no_create=None, no_destroy=None):
    success = True
    masterPublicAddress = None
    try:
        if not no_create:
            _log("Creating K8s cluster from " + str(os.path.basename(tfvars_file)), as_banner=True)
            _terraform("init")
            _terraform("get")
            _terraform("apply -var disable_auto_retries=false -auto-approve -var-file=" + tfvars_file)

        # Verify expected Terraform outputs are present
        _log("Verifying select Terraform outputs", as_banner=True)
        #  stdout = _terraform("output", "-json")

        # Figure out which IP to us (master LB or instance itself)
        masterLBIPOutputJSON = json.loads(_terraform("output -json master_lb_ip"))

        if masterLBIPOutputJSON["value"] == []:
            # Use the first public IP from master_public_ips
            masterPublicIPsOutputJSON = json.loads(_terraform("output -json master_public_ips"))
            masterPublicAddress = masterPublicIPsOutputJSON["value"][0]
        else:
            # Use the master LB public IP
            masterPublicAddress = masterLBIPOutputJSON["value"][0]

        masterURL = "https://" + masterPublicAddress + ":443"

        outputJSON = json.loads(_terraform("output -json worker_public_ips"))
        numWorkers = len(outputJSON["value"])
        workerPublicAddressList = _utf_encode_list(outputJSON["value"])

        outputJSON = json.loads(_terraform("output -json control_plane_subnet_access"))
        controlPlaneSubnetAccess = outputJSON["value"]

        _log("K8s Master URL: " + masterURL)
        _log("K8s Worker Public Addresses: " + str(workerPublicAddressList))

        # Verify master becomes ready
        _log("Waiting for /healthz end-point to become available", as_banner=True)
        healthzOK = lambda: requests.get(masterURL + "/healthz",
                                         proxies={}, verify=False).text == "ok"
        _wait_until(healthzOK, 600)
        _log(requests.get(masterURL + "/healthz", proxies={}, verify=False).text)

        # Verify worker nodes become ready
        _log("Waiting for " + str(numWorkers) + " K8s worker nodes to become ready", as_banner=True)

        nodesReady = lambda: len(_kubectl("get nodes --selector=node-role.kubernetes.io/node -o name", exit_on_error=True).splitlines()) >= numWorkers
        _wait_until(nodesReady, 300)
        workerList = _kubectl("get nodes --selector=node-role.kubernetes.io/node -o name", exit_on_error=True)
        _log(str(workerList))

        # Deploy
        _log("Deploying the hello service", as_banner=True)
        _kubectl("apply -f " + TEST_ROOT_DIR + "/resources/hello-service.yml", exit_on_error=True)
        time.sleep(5)
        _kubectl("apply -f " + TEST_ROOT_DIR + "/resources/frontend-service.yml", exit_on_error=True)

        # TODO poll instead of hard sleep
        _log("Sleeping 60 seconds to let pods initialize", as_banner=True)
        time.sleep(60)

        helloServicePort = _kubectl("get svc/hello -o jsonpath={.spec.ports[0].nodePort}", exit_on_error=True)
        _log("Hello service port: " + str(helloServicePort))

        frontendServicePort = _kubectl("get svc/frontend -o jsonpath={.spec.ports[0].nodePort}", exit_on_error=True)
        _log("Frontend service port: " + str(frontendServicePort))

        if controlPlaneSubnetAccess == "public":
            # Ping deployment
            _log("Pinging hello and frontend deployments for each K8s worker", as_banner=True)
            for workerPublicAddress in workerPublicAddressList:
                serviceAddressList = ["http://" + workerPublicAddress + ":" + str(helloServicePort),
                                      "http://" + workerPublicAddress + ":" + str(frontendServicePort)]
                for serviceAddress in serviceAddressList:
                    _log("Checking " + serviceAddress)
                    deploymentReady = lambda: requests.get(serviceAddress).status_code == 200
                    _wait_until(deploymentReady, 300)

    except Exception, e:
        _log("Unexpected error:", str(e))
        _log(_kubectl("get pods --all-namespaces"))
        _log(_kubectl("get daemonsets --all-namespaces"))
        traceback.print_exc()
        success = False
    finally:
        if masterPublicAddress != None:
            _log("Undeploying the hello service", as_banner=True)
            _kubectl("delete -f " + TEST_ROOT_DIR + "/resources/hello-service.yml", exit_on_error=False)
            _kubectl("delete -f " + TEST_ROOT_DIR + "/resources/frontend-service.yml", exit_on_error=False)

    if not no_destroy:
        _log("Destroying the K8s cluster from " + str(os.path.basename(tfvars_file)), as_banner=True)
        _terraform("destroy -force -var disable_auto_retries=true -var-file=" + tfvars_file)

    return success


def _main():
    args = _handle_args()

    _check_env()

    if not args.tfvars_file:
        for next_tfvars_file in os.listdir(TEST_ROOT_DIR + "/resources/configs/"):
            next_succcess = _verifyConfig(TEST_ROOT_DIR + "/resources/configs/" + next_tfvars_file, args.no_create,
                                          args.no_destroy)
            if not next_succcess:
                sys.exit(1)
    else:
        success = _verifyConfig(args.tfvars_file, args.no_create, args.no_destroy)
        if not success:
            sys.exit(1)


if __name__ == "__main__":
    _main()
