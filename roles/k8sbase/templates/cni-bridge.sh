#!/bin/bash
set -e
/sbin/ip link add name cni0 type bridge | true
/sbin/ip addr flush dev cni0
/sbin/ip addr add $(grep '^FLANNEL_SUBNET' /run/flannel/subnet.env | cut -d= -f2) dev cni0
/sbin/ip link set dev cni0 up