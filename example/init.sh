#! /usr/bin/env bash
#
# This is the first script to be run by cloud-init:
#  * clone the needed git repositories
#  * start the autoconf script
#

sync_git() {
	git clone $1 $2 || sleep 5
	test -e $2 || git clone $1 $2
}

# Create folders to clone roles (one folder per source repo)
for repo in github ; do
	mkdir -p /etc/ansible/roles/$repo
done

# Create local facts folder
mkdir -p /etc/ansible/facts.d

# Get the required roles
for l in $(cat $ANSIBLE_REQUIREMENTS_FILE) ; do
	export src=$(echo $l | awk -F, '{print $1}')
	export dest=$(echo $l | awk -F, '{print $2}')
	export branch=$(echo $l | awk -F, '{print $3}')
	
	export git_clone="git clone -b $branch $src $dest"
	
	$git_clone || sleep 5
	test -e $dest || $git_clone
done

# Start the autoconf script
. /etc/ansible/roles/github/cloud-dbaas-ansible/autoconf.sh

