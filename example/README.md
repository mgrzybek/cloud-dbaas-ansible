# git-ops example

These files should be used in another git repository:
* ansible_requirents.txt: a comma-separated list of playbooks to clone (src, dest, checkout)
* instances_variables.yml: variables used to configure the nodes by cloud-init
* openstack_variables.yml: variables used to create the main HEAT stacks
* openstack_variables_db.yml: variables used to create a database
