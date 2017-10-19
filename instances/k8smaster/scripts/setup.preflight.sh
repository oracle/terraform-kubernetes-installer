#!/bin/bash -x

EXTERNAL_IP=$(curl -s -m 10 http://whatismyip.akamai.com/)

mkdir -p /etc/kubernetes/auth /etc/kubernetes/manifests/

bash -x /root/setup.sh | tee -a /root/setup.log
