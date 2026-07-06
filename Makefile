.RECIPEPREFIX := >
SHELL := /bin/bash

ANSIBLE_INVENTORY ?= inventories/production.ini
GEN_PLAYBOOK := playbooks/generate_ansible_cfg.yml
REDHAT_AH_TOKEN ?=
EXTRA_E ?=

.PHONY: deps cfg inventory syntax dry-run smoke preflight clean

# Install required collections
deps:
> ANSIBLE_STDOUT_CALLBACK=default ANSIBLE_LOG_PATH="/tmp/aap_migration_ansible.log" ansible-galaxy collection install -r requirements.yml

# Render ansible.cfg from template (bootstrap with a writable log path)
cfg:
> @echo "Rendering ansible.cfg from template..."
> LOG_TARGET="$${ANSIBLE_LOG_PATH:-/tmp/aap_migration_ansible.log}"; DIR="$${LOG_TARGET%/*}"; [ -n "$$DIR" ] && mkdir -p "$$DIR"
> ANSIBLE_STDOUT_CALLBACK=default ANSIBLE_LOG_PATH="$$LOG_TARGET" REDHAT_AH_TOKEN="$(REDHAT_AH_TOKEN)" ansible-playbook -i "$(ANSIBLE_INVENTORY)" "$(GEN_PLAYBOOK)" $(EXTRA_E)

# Preflight connectivity and trust checks
preflight:
> ANSIBLE_STDOUT_CALLBACK=default ANSIBLE_LOG_PATH="/tmp/aap_migration_ansible.log" ansible-playbook -i "$(ANSIBLE_INVENTORY)" playbooks/03_preflight_connectivity.yml $(EXTRA_E)

# Inventory, syntax, dry-run, smoke (unchanged)
inventory:
> ansible-inventory -i "$(ANSIBLE_INVENTORY)" --list

syntax:
> @if [ -z "$(CHECK_PLAYBOOK)" ]; then echo "Set CHECK_PLAYBOOK=<path/to/playbook.yml>"; exit 1; fi
> ansible-playbook -i "$(ANSIBLE_INVENTORY)" "$(CHECK_PLAYBOOK)" --syntax-check $(EXTRA_E)

dry-run:
> @if [ -z "$(CHECK_PLAYBOOK)" ]; then echo "Set CHECK_PLAYBOOK=<path/to/playbook.yml>"; exit 1; fi
> ansible-playbook -i "$(ANSIBLE_INVENTORY)" "$(CHECK_PLAYBOOK)" --check $(EXTRA_E)

smoke: cfg
> ansible-inventory -i "$(ANSIBLE_INVENTORY)" --list
> @if [ -z "$(CHECK_PLAYBOOK)" ]; then echo "Set CHECK_PLAYBOOK=<path/to/playbook.yml>"; exit 1; fi
> ansible-playbook -i "$(ANSIBLE_INVENTORY)" "$(CHECK_PLAYBOOK)" --syntax-check $(EXTRA_E)
> ansible-playbook -i "$(ANSIBLE_INVENTORY)" "$(CHECK_PLAYBOOK)" --check $(EXTRA_E)

clean:
> rm -f ansible.cfg
> rm -rf logs