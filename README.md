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

```bash
# Copy the configuration files to a git-ops repo
export GITOPS=~/my-gitops-repo
export BRANCH=my-branch
cd $GITOPS
git checkout -b $BRANCH
cd -
mkdir -p $GITOPS/{etc,files}
cp example/*.yml $GITOPS/etc
cp example/*.txt $GITOPS/etc
# Create an openrc file
vi $GITOPS/files/openrc.sh
# Update the repo
cd $GITOPS
git add *
git commit -a -m "First commit to branch $BRANCH"
git push
```

### The commands to run

```bash
export DBAAS_PLAYBOOK=../cloud-dbaas-ansible
# Create the control-plane
ansible-playbook $DBAAS_PLAYBOOK/control-plane.yml -e@etc/control_plane.yml
```
The HEAT stacks are deployed.

`hosts.ini` has been written and provides Nomad's endpoint address.

```bash
# Create a PostgreSQL database
ansible-playbook $DBAAS_PLAYBOOK/database.yml \
  -e type=postgresql \
  -e db_name=my-first-db \
  -e db_size_gb=10
```
`my-first-db.yml` has been written and contains how to connect against the database.

```bash
# Add the new database to gitops
git add my-first-db.yml
git commit my-first-db.yml -m "New DB my-first-db"
git push
```
