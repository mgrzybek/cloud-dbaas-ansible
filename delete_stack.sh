#!/usr/bin/env bash

for s in control-plane ; do
        if openstack stack list | grep -qw $s ; then
                ansible localhost -m os_stack -o -a "name=$s state=absent" || exit 1
        fi
done

if [ -f hosts.ini ] ; then
	for i in $(awk -F= '/ansible_ssh_host/ {print $2}' hosts.ini) ; do
		ssh-keygen -f $HOME/.ssh/known_hosts -R $i
	done
fi

rm -f .consul.env .nomad.env .vault.env *.retry heat-*.yml ssh.cfg hosts.ini

