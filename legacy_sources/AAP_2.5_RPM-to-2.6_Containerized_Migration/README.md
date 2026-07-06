# RHEL AAP 2.5 RPM to AAP 2.6 Containerized Upgrade

# Table Of Contents

- [Synopsys](#synopsys)
- [How To Run The Role](#how-to-run-the-role)
- [Role Layout](#role-layout)
- [Variables And Naming](#variables-and-naming)
- [Validation](#validation)
- [Safety Notes](#safety-notes)

## Synopsys

`RHEL_AAP_Upgrade` automates migration from **Red Hat Ansible Automation Platform 2.5 (RPM)** to **AAP 2.6 (containerized)** using the role `aap_25_to_26_migration`.

The workflow is designed to be safe and repeatable:

- preflight checks and optional dry run
- export/import of controller-related configuration
- installer inventory generation for `single_node` or `growth`
- post-migration validation and smoke testing

## How To Run The Role

Quick path:

```bash
ansible-galaxy collection install -r requirements.yml
./scripts/prompt_group_vars_setup.sh
ansible-vault encrypt group_vars/vault.yml
ansible-playbook migrate_aap_25_to_26.yml --ask-vault-pass
```

### 1. Prepare dependencies

```bash
ansible-galaxy collection install -r requirements.yml
```

### 2. Generate variable files

Recommended one-command interactive setup:

```bash
./scripts/prompt_group_vars_setup.sh
```

This runs:

1. `scripts/prompt_group_vars_all.yml`
2. `scripts/prompt_group_vars_vault.yml`

Then encrypt secrets:

```bash
ansible-vault encrypt group_vars/vault.yml
```

Manual alternative:

```bash
mkdir -p group_vars
cp group_vars/all.yml.example group_vars/all.yml
cp group_vars/vault.yml.example group_vars/vault.yml
ansible-vault encrypt group_vars/vault.yml
```

### 3. Run the migration playbook

Dry run / preflight first:

```bash
ansible-playbook migrate_aap_25_to_26.yml --ask-vault-pass
```

Full run (after setting `aap_25_to_26_migration_dry_run: false` in `group_vars/all.yml`):

```bash
ansible-playbook migrate_aap_25_to_26.yml --ask-vault-pass
```

### Example: Run single-node topology

```yaml
# group_vars/all.yml
aap_25_to_26_migration_deployment_type: single_node
aap_25_to_26_migration_old_rpm_host: old-aap-25.example.com
aap_25_to_26_migration_new_container_host: new-aap.example.com
aap_25_to_26_migration_single_node_host: new-aap.example.com
aap_25_to_26_migration_dry_run: true
```

### Example: Growth topology

```yaml
# group_vars/all.yml
aap_25_to_26_migration_deployment_type: growth
aap_25_to_26_migration_new_container_host: new-aap.example.com
aap_25_to_26_migration_external_db_host: externaldb.example.org
aap_25_to_26_migration_gateway_pg_host: "{{ aap_25_to_26_migration_external_db_host }}"
aap_25_to_26_migration_controller_pg_host: "{{ aap_25_to_26_migration_external_db_host }}"
aap_25_to_26_migration_hub_pg_host: "{{ aap_25_to_26_migration_external_db_host }}"
aap_25_to_26_migration_eda_pg_host: "{{ aap_25_to_26_migration_external_db_host }}"
aap_25_to_26_migration_dry_run: true
```

## Role Layout

- Role: `roles/aap_25_to_26_migration`
- Entrypoint playbook: `migrate_aap_25_to_26.yml`
- Prompt helpers: `scripts/prompt_group_vars_all.yml`, `scripts/prompt_group_vars_vault.yml`

## Variables And Naming

- Role variables are namespaced as `aap_25_to_26_migration_*`.
- Rendered AAP installer inventory uses canonical installer keys like `postgresql_admin_username`, `gateway_admin_password`, and `controller_pg_host`.

## Validation

Run the smoke suite:

```bash
./scripts/smoke_test.sh
```

It checks:

1. Playbook syntax
2. `ansible-lint`
3. Inventory rendering for `inventory.j2` and `inventory-growth.j2`

## Safety Notes

- Keep the old RPM environment unchanged until migration validation is complete.
- Keep backup artifacts from `setup.sh -b`.
- Keep exported API configuration in `aap_25_to_26_migration_export_dir`.
