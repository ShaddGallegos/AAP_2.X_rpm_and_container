# AAP 2.X RPM and Container Migration Factory

This project merges:

- AAP_2.5_RPM-to-2.6_Containerized_Migration
- AAP_2.6-2.7
- AAP_Migration
- HealthChecks/AAP_Healthcheck

into a single automation project for AAP 2.x migrations, upgrades, backups, restores, healthchecks, and configuration-as-code disaster recovery workflows.

## Included Capabilities

- Backup and restore playbooks for RPM and containerized stages.
- Migration and upgrade coverage for RPM -> RPM, RPM -> containerized, containerized -> containerized, and containerized -> OpenShift where applicable.
- Healthcheck and optional tuning role (aap_healthcheck) that installs required packages when needed.
- Config-as-code export role (aap_configuration_as_code) that produces a rebuild bundle.
- Dynamic menu-driven bash launcher for operations and sub-operations.

## Scenario Coverage Matrix

### Core scenarios

- 2.4 RPM -> 2.5 RPM -> 2.6 containerized:
  - playbooks/migrate_24_25_26.yml
- 2.5 RPM -> 2.6 containerized (legacy export/import flow):
  - playbooks/migrate_25rpm_to_26containerized_legacy.yml
- 2.6 RPM -> 2.6 containerized:
  - playbooks/migrate_26rpm_to_26containerized.yml
- 2.6 RPM -> 2.7 containerized:
  - playbooks/migrate_26rpm_to_27containerized.yml
- 2.6 containerized -> 2.7 containerized:
  - playbooks/migrate_26containerized_to_27containerized.yml
- 2.6 containerized -> 2.7 OpenShift:
  - playbooks/migrate_26containerized_to_27openshift.yml
- 2.6 containerized -> 2.6 OpenShift:
  - playbooks/migrate_26containerized_to_26openshift.yml

### Healthcheck

- playbooks/06_aap_healthcheck.yml

### Config-as-code

- Generate bundle:
  - playbooks/110_generate_config_as_code_bundle.yml
- Recreate from generated defaults:
  - playbooks/111_recreate_environment_from_cac.yml

### Scenario dispatcher

- playbooks/aap_2x_master_orchestrator.yml
  - Example:
    - ansible-playbook playbooks/aap_2x_master_orchestrator.yml -e aap_scenario=26containerized_to_27openshift

## Dynamic Menu Script

- scripts/aap_2x_menu.sh

Run:

```bash
chmod +x scripts/aap_2x_menu.sh
./scripts/aap_2x_menu.sh
```

The script provides nested options for:

- Healthcheck and tuning
- Migrations/upgrades
- Restore operations
- Config-as-code bundle generation and environment recreation

## Config-as-Code Workflow

Generate bundle:

```bash
ansible-playbook playbooks/110_generate_config_as_code_bundle.yml --ask-vault-pass
```

Bundle output is created under config_as_code/ (ignored by git).

Recreate environment:

```bash
ansible-playbook -i config_as_code/inventories/production.ini config_as_code/playbooks/recreate_aap_environment.yml --ask-vault-pass
```

## Dependencies

Install collections:

```bash
ansible-galaxy collection install -r requirements.yml
```

Run full syntax validation locally:

```bash
make validate-all
```

Run scenario-chain validation locally (required vars + syntax checks):

```bash
make validate-scenario SCENARIO=26containerized_to_27openshift
```

CI pipeline:

- `.github/workflows/ci.yml` runs playbook syntax checks, `yamllint`, and `ansible-lint` on push and pull requests.

## Disaster Recovery Reminder

Before DR or rebuild runs, copy your existing environment and vault pass files into place so the same encrypted context is reused:

- ~/.ansible/conf/env.yml
- ~/.ansible/conf/.vaultpass.txt

Keep those files secured and available on your control node.

## Project Hygiene

- Keep inventories and vault files outside source control.
- Rotate API tokens and registry credentials periodically.
- Run healthcheck before and after every migration path execution.
