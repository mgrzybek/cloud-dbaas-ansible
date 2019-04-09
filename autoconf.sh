for f in $REPO_PATH/files/*.pem ; do
	export OS_CACERT=$f
done

for f in $REPO_PATH/files/*openrc* ; do
	export OPENRC_FILE=$f
	source $f
done

export CONTROLPLANE_NODES_NUMBER=$(openstack server list --name controlplane | grep -c controlplane)

export ANSIBLE_PLAYBOOK_OPTS=" \
	/etc/ansible/roles/github/cloud-dbaas-ansible/autoconf_controlplane.yml \
	-e@$ETC_PATH/controlplane.yml \
	-e monitoring_consul_cluster={{ansible_default_ipv4.address}} \
	-e scheduler_bootstrap_expect=$CONTROLPLANE_NODES_NUMBER \
	-e monitoring_consul_ui=false \
	-e openstack_cluster_node_openrc_source=$OPENRC_FILE \
	-e openstack_cluster_node_ca_cert_source=$OS_CACERT"

# Master auto-conf
if echo $HOSTNAME | grep -q controlplane ; then
	ansible-playbook $ANSIBLE_PLAYBOOK_OPTS -t os-ready,controlplane \
		-e monitoring_server_mode=true \
		-e scheduler_config_consul=true \
		-e scheduler_server_mode=true \
		-e dnsmasq_listening_interfaces=''
fi

# LB auto-conf
if echo $HOSTNAME | grep -q lb ; then
	source /etc/ansible/roles/github/cloud-exploitation-ansible/files/generate_local_facts.sh lb

	export PUBLIC_IP=$(openstack stack show ip -c outputs -f yaml \
		| grep -A 1 publication_floating_ip_id \
		| awk '/output_value:/ {print $NF}')
	
	export CORE_VOLUME=$( openstack volume list -f value \
		| fgrep $HOSTNAME \
		| awk '/core/ {print $1}')

	export ANSIBLE_PLAYBOOK_OPTS="$ANSIBLE_PLAYBOOK_OPTS \
		-e cluster_node_attribute_value=lb \
		-e publication_floating_ip_id=$PUBLIC_IP \
		-e monitoring_consul_ui=true \
		-e dnsmasq_listening_interfaces=''"

	ansible-playbook $ANSIBLE_PLAYBOOK_OPTS -t os-ready,pacemaker,lb

	sleep 120

	crm_resource --cleanup --resource traefik-service
	crm_resource --cleanup --resource publication-ip
	
	if ! /usr/local/bin/consul members | grep -q server ; then
		crm_resource --restart --resource consul-service
	fi
	
	sleep 30
	crm_resource --cleanup --resource consul-info
fi

# DB auto-conf
if echo $HOSTNAME | grep -q db ; then
	source /etc/ansible/roles/github/cloud-exploitation-ansible/files/generate_local_facts.sh db
	
	export DOCKER_VOLUME=$(openstack volume list -f value \
		| fgrep $HOSTNAME \
		| awk '/docker/ {print $1}')
	
	export CORE_VOLUME=$(openstack volume list -f value \
		| fgrep $HOSTNAME \
		| awk '/core/ {print $1}')	

	export ANSIBLE_PLAYBOOK_OPTS="$ANSIBLE_PLAYBOOK_OPTS \
		-e cluster_node_attribute_value=$DB_NAME"

	if lsb_release -d | grep -qi ubuntu ; then
		export ANSIBLE_PLAYBOOK_OPTS="$ANSIBLE_PLAYBOOK_OPTS \
			-e ha_storage_openstack_cloud_info_resource=c-cloud-info"
	fi

	ansible-playbook $ANSIBLE_PLAYBOOK_OPTS -t os-ready
	ansible-playbook $ANSIBLE_PLAYBOOK_OPTS -t node \
		-e 'docker_options="--dns {{ansible_docker0.ipv4.address}}"'
	ansible-playbook $ANSIBLE_PLAYBOOK_OPTS -t pacemaker
	sleep 20
	crm_resource --cleanup

	if ! /usr/local/bin/consul members | grep -q server ; then
		crm_resource --restart --resource consul-service
	fi

fi

# Bastion auto-conf
if echo $HOSTNAME | grep -q bastion ; then
	ansible-playbook $ANSIBLE_PLAYBOOK_OPTS -t os-ready
fi
