#!/usr/bin/env bash

function replace {
        echo "${1//$2/$3}"
}

function lower {
        echo "$1" | tr '[:upper:]' '[:lower:]'
}


# install JQ package
curl -sL --retry 3 http://169.254.169.254/opc/v1/instance/ | tee /tmp/instance_meta.json

HOSTNAME=$(hostname)
EXTERNAL_IP=$(curl -s -m 10 http://whatismyip.akamai.com/)
AVAILABILITY_DOMAIN=$(jq -r '.availabilityDomain' /tmp/instance_meta.json | sed 's/:/-/g')
ZONE=$(lower replace "$AVAILABILITY_DOMAIN" ":" "-" )
read COMPARTMENT_ID_0 COMPARTMENT_ID_1 <<< $(jq -r '.compartmentId' /tmp/instance_meta.json | perl -pe 's/(.*?\.){4}\K/ /g' | perl -pe 's/\.+\s/ /g')
read NODE_ID_0 NODE_ID_1 <<< $(jq -r '.id' /tmp/instance_meta.json | perl -pe 's/(.*?\.){4}\K/ /g' | perl -pe 's/\.+\s/ /g')
NODE_SHAPE=$(jq -r '.shape' /tmp/instance_meta.json)

sed -e "s/__FQDN_HOSTNAME__/$HOSTNAME/g" \
    -e "s/__EXT_IP__/$EXTERNAL_IP/g" \
    -e "s/__ZONE__/$ZONE/g" \
    -e "s/__AVAILABILITY_DOMAIN__/$AVAILABILITY_DOMAIN/g" \
    -e "s/__COMPARTMENT_ID_PREFIX__/$COMPARTMENT_ID_0/g" \
    -e "s/__COMPARTMENT_ID_SUFFIX__/$COMPARTMENT_ID_1/g" \
    -e "s/__NODE_ID_PREFIX__/$NODE_ID_0/g" \
    -e "s/__NODE_ID_SUFFIX__/$NODE_ID_1/g" \
    -e "s/__NODE_SHAPE__/$NODE_SHAPE/g" \
    /home/opc/services/kubelet.service > /etc/systemd/system/kubelet.service