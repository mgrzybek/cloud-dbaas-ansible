###############################################################################
#
# Configuration
#
#GIT_BRANCH=$(shell git rev-parse --abbrev-ref HEAD)
#NUAGE=$(shell echo ${OS_AUTH_URL} | awk -F/ '{print $$3}' | awk -F. '{print $$1}')
#CONSUL_HTTP_ADDR=http://gestion.${NUAGE}.${GIT_BRANCH}.supervision.dgfip.finances.rie.gouv.fr
#NOMAD_ADDR=http://orchestration.${NUAGE}.${GIT_BRANCH}.supervision.dgfip.finances.rie.gouv.fr
#NOMAD_TOKEN=$(shell awk -F= '{print $$2}' .nomad.env)

#export NOMAD_TOKEN
#export NOMAD_ADDR
#export CONSUL_HTTP_ADDR

#.PHONY: init # Show environment variables
#init:
#	@echo "git branch: $(GIT_BRANCH)"
#	@echo "nuage: ${NUAGE}"
#	@echo "consul: ${CONSUL_HTTP_ADDR}"
#	@echo "nomad: ${NOMAD_ADDR}"

.PHONY: test # Testing YAML syntax, env variables and openstack connectivity
test:
	$(shell [ -z ${CLOUD_ANSIBLE} ] && echo CLOUD_ANSIBLE is not set && exit 1)
	$(shell test -d ${CLOUD_ANSIBLE} || echo CLOUD_ANSIBLE does not exist)

#	$(shell test -z ${CONSUL_HTTP_ADDR} && echo CONSUL_HTTP_ADDR is not set && exit 1)
#	$(shell test -z ${NOMAD_ADDR} && echo NOMAD_ADDR is not set && exit 1)
	
#	$(shell test -z ${GIT_BRANCH} && echo GIT_BRANCH is not set && exit 1)
#	$(shell test -z ${NUAGE} && echo NUAGE is not set && exit 1)

	@openstack stack list 1>/dev/null

.PHONY: status # Get some information about what is running
status: test
	@echo "Projet: ${OS_PROJECT_NAME}"
	@echo "Cloud: ${OS_AUTH_URL}"
	@echo "#######################################################"
	openstack stack list
	@echo "#######################################################"
	consul members
	@echo "#######################################################"
	consul catalog services
	@echo "#######################################################"
	nomad status
	@echo "#######################################################"
	consul catalog services
	
.PHONY: help # This help message
help:
	@grep '^.PHONY: .* #' Makefile \
		| sed 's/\.PHONY: \(.*\) # \(.*\)/\1\t\2/' \
		| expand -t20 \
		| sort

###############################################################################
#
# HEAT stack
#
.PHONY: controplane # Build the controplane
controplane:
	@ansible-playbook ${CLOUD_ANSIBLE}/openstack_control-plane.yml \
		-e @etc/controlplane.yml \
		-e gitops_repo_checkout=${GIT_BRANCH}

.PHONY: stack-clean # Destroy HEAT stacks
stack-clean: 
	@${CLOUD_ANSIBLE}/delete_stack.sh
	rm -f .nomad.env

###############################################################################
#
# Hosted services
#

###############################################################################
#
# Stack + services
#
.PHONY: all # Deploy the full stack (HEAT + services)
all: test controplane
	@echo

.PHONY: clean # Destroy the full stack
clean: stack-clean
	@openstack stack list
	#ssh-keygen -f ${HOME}/.ssh/known_hosts -R 100.67.226.67

.PHONY: rebuild # Destroy and build the full stack
rebuild: clean all
	@echo


###############################################################################
#
# Maintenance
#
