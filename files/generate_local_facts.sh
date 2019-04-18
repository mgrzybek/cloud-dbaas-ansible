#! /usr/bin/env bash
#
# Build a local Ansible facts file using Openstack API.
# This is used by ansible-ha-cluster playbook.
# Environment variables should be present.
#

openstack server list -f json -c Name -c Networks --name $1 \
	| perl -pe 's/(\w|-)+=//g ; s/N/n/ ; s/networks/ring0_address/ ; s/, .+?"/"/' \
	> /etc/ansible/facts.d/cluster_nodes.fact

