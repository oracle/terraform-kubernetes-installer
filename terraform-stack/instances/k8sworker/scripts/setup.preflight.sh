#!/bin/bash -x

EXTERNAL_IP=$(curl -s -m 10 http://whatismyip.akamai.com/)

mkdir -p /etc/kubernetes/manifests /etc/kubernetes/auth

# add tools
curl --retry 3 http://stedolan.github.io/jq/download/linux64/jq -o /usr/local/bin/jq && chmod +x /usr/local/bin/jq
bash -x /root/setup.sh 2>&1 | tee -a /root/setup.log
