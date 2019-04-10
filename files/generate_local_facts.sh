#! /usr/bin/env bash

#if [ -z $OS_CACERT ] ; then
#    for f in $REPO_PATH/files/*.pem ; do
#        export OS_CACERT=$f
#    done
#fi

openstack server list -f json -c Name -c Networks --name $1 \
	| perl -pe 's/(\w|-)+=//g ; s/N/n/ ; s/networks/ring0_address/ ; s/, .+?"/"/' \
	> /etc/ansible/facts.d/cluster_nodes.fact
