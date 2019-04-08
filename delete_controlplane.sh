#!/bin/sh

for s in control-plane ; do
	if openstack stack list | grep -q $s ; then
		openstack stack delete --yes --wait $s || exit 1
	fi
done

rm -f hosts.ini
