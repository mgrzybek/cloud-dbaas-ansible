# cloud-dbaas-ansible
Ansible-based DBaaS automation for Openstack projects.

## The core architecture

### Infrastructure

These playbooks are used to deploy and manage persistant-storage-based workloads:
* in order to provide high-availability and fencing, pacemaker is used ;
* in order to manage the worklodas, nomad is used.

These playbooks also provide a control plane:
* consul & nomad masters.

### Security

The user cannot login as administrator from outside of the cluster.

## Database management

### Provisionning

Each database is hosted on a dedicated pacemaker cluster. On the cluster side, a resource group is created:
* the cinder volume ;
* the mountpoints ;
* the floating IP ;
* the docker daemon ;
* the nomad agent.

Some nomad tasks are created:
* a service task to run the database engine ;
* a batch task to configure the database (users, schemas…).

### Batchs

When the user wants to run some SQL administration queries, a nomad batch task is used.
