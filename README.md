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

## Usage

### The configuration files

### The commands to run

```bash
# Create the control-plane
ansible-playbook control-plane.yml -e@etc/control_plane.yml
```
The HEAT stacks are deployed.
`hosts.ini` has been written and provides Nomad's endpoint address.

```bash
# Create a PostgreSQL database
ansible-playbook db.yml \
  -e type=postgresql \
  -e db_name=my-first-db \
  -e db_size_gb=10
```
`my-first-db.yml` has been written and contains how to connect against the database.
