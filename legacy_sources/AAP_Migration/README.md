# Ansible Automation Platform: Upgrade & Migration Toolkit (2.4 → 2.5 → 2.6)

This project includes both:

- Strategic guidance for migrating AAP 2.4 → 2.5 → 2.6
- Automation playbooks and roles to snapshot VMware, run backups + sosreports, perform upgrades, validate functionality, and generate stage-by-stage reports.

## Quick run 

Use the top-level orchestrator to run the entire flow end-to-end (config → preflight → full migration):

- [setup-site.yml](setup-site.yml)
- [playbooks/generate_ansible_cfg.yml](playbooks/generate_ansible_cfg.yml)
- [playbooks/03_preflight_connectivity.yml](playbooks/03_preflight_connectivity.yml)
- [playbooks/migrate_24_25_26.yml](playbooks/migrate_24_25_26.yml)

From the project root:
```bash
cd /run/media/sgallego/SD_Card/GIT/AAP_Migration
ansible-playbook setup-site.yml
```

Optionally provide preflight overrides (node names, SSH user, known_hosts fix):
- [playbooks/preflight.vars.yml](playbooks/preflight.vars.yml)
```bash
cd /run/media/sgallego/SD_Card/GIT/AAP_Migration
ansible-playbook setup-site.yml -e @playbooks/preflight.vars.yml
```

If you run from outside the project root, point Ansible to the project config:
```bash
ANSIBLE_CONFIG=/run/media/sgallego/SD_Card/GIT/AAP_Migration/ansible.cfg \
ansible-playbook /run/media/sgallego/SD_Card/GIT/AAP_Migration/setup-site.yml
```

## Prerequisites

- Inventory: update [inventories/production.ini](inventories/production.ini)
- Group vars: copy and adjust `group_vars/all.yml` (use Vault for secrets)
- Collections: install from [requirements.yml](requirements.yml)
```bash
cd /run/media/sgallego/SD_Card/GIT/AAP_Migration
ansible-galaxy collection install -r requirements.yml
```

Offline/air-gapped option (pre-downloaded tarballs):
- [collections_cache/requirements.yml](collections_cache/requirements.yml)

## Makefile helpers

- [Makefile](Makefile)
```bash
# Install collections
make deps

# Render ansible.cfg from template (uses REDHAT_AH_TOKEN if set)
make cfg REDHAT_AH_TOKEN=xxxx

# Syntax-check any playbook
make syntax CHECK_PLAYBOOK=playbooks/migrate_24_25_26.yml

# Preflight connectivity
make preflight
```

## What the automation does

Artifacts are written to:
- `reports/` (stage reports + backup summaries)
- `sosreports/` (sosreport archives fetched from targets)

- Pre-migration health check:
  - [playbooks/05_pre_migration_healthcheck.yml](playbooks/05_pre_migration_healthcheck.yml)
- Snapshots:
  - [playbooks/10_snapshot_24.yml](playbooks/10_snapshot_24.yml)
  - [playbooks/50_snapshot_25.yml](playbooks/50_snapshot_25.yml)
- Backups + sosreport:
  - [playbooks/20_backup_24.yml](playbooks/20_backup_24.yml)
  - [playbooks/60_backup_25.yml](playbooks/60_backup_25.yml)
  - [playbooks/85_backup_26.yml](playbooks/85_backup_26.yml)
  - [playbooks/86_backup_26_pre_27.yml](playbooks/86_backup_26_pre_27.yml)
  - [playbooks/87_backup_26_rpm_pre_27_containerized.yml](playbooks/87_backup_26_rpm_pre_27_containerized.yml)
  - [playbooks/88_backup_26_containerized_pre_27_containerized.yml](playbooks/88_backup_26_containerized_pre_27_containerized.yml)
  - [playbooks/89_backup_26_rpm_pre_26_containerized.yml](playbooks/89_backup_26_rpm_pre_26_containerized.yml)
  - [playbooks/91_backup_26_containerized_pre_27_openshift.yml](playbooks/91_backup_26_containerized_pre_27_openshift.yml)
  - [playbooks/96_backup_26_containerized_pre_26_openshift.yml](playbooks/96_backup_26_containerized_pre_26_openshift.yml)
- Upgrades:
  - [playbooks/30_upgrade_24_to_25.yml](playbooks/30_upgrade_24_to_25.yml)
  - [playbooks/70_upgrade_25_to_26.yml](playbooks/70_upgrade_25_to_26.yml)
  - [playbooks/92_upgrade_26_rpm_to_27_containerized.yml](playbooks/92_upgrade_26_rpm_to_27_containerized.yml)
  - [playbooks/93_upgrade_26_containerized_to_27_containerized.yml](playbooks/93_upgrade_26_containerized_to_27_containerized.yml)
  - [playbooks/100_upgrade_26_rpm_to_26_containerized.yml](playbooks/100_upgrade_26_rpm_to_26_containerized.yml)
  - [playbooks/101_upgrade_26_containerized_to_27_openshift.yml](playbooks/101_upgrade_26_containerized_to_27_openshift.yml)
  - [playbooks/102_upgrade_26_containerized_to_26_openshift.yml](playbooks/102_upgrade_26_containerized_to_26_openshift.yml)
- Validation:
  - [playbooks/40_validate_25.yml](playbooks/40_validate_25.yml)
  - [playbooks/80_validate_26.yml](playbooks/80_validate_26.yml)
- Functional smoke tests (Controller API):
  - [playbooks/45_smoke_test_25.yml](playbooks/45_smoke_test_25.yml)
  - [playbooks/82_smoke_test_26.yml](playbooks/82_smoke_test_26.yml)
- Rollback:
  - [playbooks/rollback_to_snapshot_24.yml](playbooks/rollback_to_snapshot_24.yml)
  - [playbooks/rollback_to_snapshot_25.yml](playbooks/rollback_to_snapshot_25.yml)
  - [playbooks/restore_from_backup.yml](playbooks/restore_from_backup.yml)
  - [playbooks/94_restore_26_rpm_pre_27_containerized.yml](playbooks/94_restore_26_rpm_pre_27_containerized.yml)
  - [playbooks/95_restore_26_containerized_pre_27_containerized.yml](playbooks/95_restore_26_containerized_pre_27_containerized.yml)
  - [playbooks/103_restore_26_rpm_pre_26_containerized.yml](playbooks/103_restore_26_rpm_pre_26_containerized.yml)
  - [playbooks/104_restore_26_containerized_pre_27_openshift.yml](playbooks/104_restore_26_containerized_pre_27_openshift.yml)
  - [playbooks/105_restore_26_containerized_pre_26_openshift.yml](playbooks/105_restore_26_containerized_pre_26_openshift.yml)

## 2.6 -> 2.7 containerized migration paths

This toolkit now includes backup-first playbooks for two supported paths:

- 2.6 RPM -> 2.7 containerized:
  - [playbooks/migrate_26rpm_to_27containerized.yml](playbooks/migrate_26rpm_to_27containerized.yml)
- 2.6 containerized -> 2.7 containerized:
  - [playbooks/migrate_26containerized_to_27containerized.yml](playbooks/migrate_26containerized_to_27containerized.yml)

Run from project root:
```bash
cd /run/media/sgallego/SD_Card/GIT/AAP_Migration
ansible-playbook playbooks/migrate_26rpm_to_27containerized.yml
```

The `playbooks/92_upgrade_26_rpm_to_27_containerized.yml` path uses role
`roles/aap_upgrade_26_rpm_to_27_containerized_openshift` to add optional
OpenShift checks (`oc` client availability, identity validation, and optional
namespace existence check) before running the installer.

or

```bash
cd /run/media/sgallego/SD_Card/GIT/AAP_Migration
ansible-playbook playbooks/migrate_26containerized_to_27containerized.yml
```

Before running, set these vars in [group_vars/all.yml](group_vars/all.yml):

- `aap27_installer_dir`
- `aap26_installer_inventory_rpm`
- `aap26_installer_inventory_containerized`
- `aap27_installer_inventory_rpm_to_containerized`
- `aap27_installer_inventory_containerized_to_containerized`
- Optional: `aap26_restore_command`
- Optional: `aap27_installer_command` (if your installer entry point is not `setup.sh`)
- Optional: `aap27_setup_extra_args`
- Optional OpenShift checks:
  - `openshift_precheck_enabled`
  - `openshift_project`
  - `openshift_check_namespace`
  - `openshift_require_login`
  - `openshift_kubeconfig`
  - `openshift_context`
  - `openshift_api_url`
  - `openshift_api_token`

Installer inventory templates for these paths are included in:

- [inventories/inventory_rpm_to_containerized](inventories/inventory_rpm_to_containerized)
- [inventories/inventory_containerized_to_containerized](inventories/inventory_containerized_to_containerized)

Copy the appropriate file to your 2.7 installer directory on target nodes (for example, `/opt/aap/installer-2.7/`) and keep the filename aligned with the corresponding `aap27_installer_inventory_*` variable.

## Additional 2.6 migration paths

This toolkit also includes these backup-first flows:

- 2.6 RPM -> 2.6 containerized:
  - [playbooks/migrate_26rpm_to_26containerized.yml](playbooks/migrate_26rpm_to_26containerized.yml)
- 2.6 containerized -> 2.7 OpenShift:
  - [playbooks/migrate_26containerized_to_27openshift.yml](playbooks/migrate_26containerized_to_27openshift.yml)
- 2.6 containerized -> 2.6 OpenShift:
  - [playbooks/migrate_26containerized_to_26openshift.yml](playbooks/migrate_26containerized_to_26openshift.yml)

Run from project root:
```bash
cd /run/media/sgallego/SD_Card/GIT/AAP_Migration
ansible-playbook playbooks/migrate_26rpm_to_26containerized.yml --ask-vault-pass
ansible-playbook playbooks/migrate_26containerized_to_27openshift.yml --ask-vault-pass
ansible-playbook playbooks/migrate_26containerized_to_26openshift.yml --ask-vault-pass
```

Installer inventory templates for these paths are included in:

- [inventories/inventory_26_rpm_to_26_containerized](inventories/inventory_26_rpm_to_26_containerized)
- [inventories/inventory_26_containerized_to_27_openshift](inventories/inventory_26_containerized_to_27_openshift)
- [inventories/inventory_26_containerized_to_26_openshift](inventories/inventory_26_containerized_to_26_openshift)

The OpenShift-targeted playbooks use role
`roles/aap_upgrade_containerized_to_openshift` to perform optional `oc`
prechecks before running the installer.

### Vaulted secrets for 2.7 inventories

Use the provided vault example to keep installer secrets out of plain text:

- [group_vars/vault.yml.example](group_vars/vault.yml.example)

Create and encrypt your vault file:
```bash
cd /run/media/sgallego/SD_Card/GIT/AAP_Migration
cp group_vars/vault.yml.example group_vars/vault.yml
ansible-vault encrypt group_vars/vault.yml
```

The 2.7 inventory templates already reference these vars:

- `vault_registry_username`
- `vault_registry_password`
- `vault_aap_admin_password`
- `vault_pg_password`
- `vault_automationhub_pg_password`
- `vault_automationhub_admin_password`

Run with vault prompt:
```bash
cd /run/media/sgallego/SD_Card/GIT/AAP_Migration
ansible-playbook playbooks/migrate_26rpm_to_27containerized.yml --ask-vault-pass
```

or

```bash
cd /run/media/sgallego/SD_Card/GIT/AAP_Migration
ansible-playbook playbooks/migrate_26containerized_to_27containerized.yml --ask-vault-pass
```

Restore commands for each 2.6 -> 2.7 option:

```bash
cd /run/media/sgallego/SD_Card/GIT/AAP_Migration
ansible-playbook playbooks/94_restore_26_rpm_pre_27_containerized.yml \
  -e aap_restore_from=/var/tmp/aap_migration_backups/<rpm_backup_file> \
  --ask-vault-pass
```

```bash
cd /run/media/sgallego/SD_Card/GIT/AAP_Migration
ansible-playbook playbooks/95_restore_26_containerized_pre_27_containerized.yml \
  -e aap_restore_from=/var/tmp/aap_migration_backups/<containerized_backup_file> \
  --ask-vault-pass
```

## Platform detection and controller prep

The orchestrator calls:
- [playbooks/00_platform_setup.yml](playbooks/00_platform_setup.yml)
  - Runs the [`platform_setup`](roles/platform_setup) role to detect infra (AWS/GCP/Azure/VMware/Nutanix/libvirt/baremetal), enable CRB/EPEL on RHEL, install needed OS/Python packages, and ensure base+platform collections.

Defaults can be tuned in:
- [roles/platform_setup/defaults/main.yml](roles/platform_setup/defaults/main.yml)

## Environment variables

- `REDHAT_AH_TOKEN`: If provided, we render [ansible.cfg](ansible.cfg) to enable authenticated pulls from Red Hat Automation Hub.
- `AAP_SSH_USER`: Preflight SSH user (default `ansible`).
- `aap_nodes_override`: List of node hostnames for preflight (optional), see [playbooks/preflight.vars.yml](playbooks/preflight.vars.yml).
- `ANSIBLE_LOG_PATH`: Used by config generation to set a writable log file path.

## Troubleshooting

- Role not found: `the role 'platform_setup' was not found`
  - Ensure you run from the project root so [ansible.cfg](ansible.cfg) is loaded and `roles_path` is correct:
    ```bash
    cd /run/media/sgallego/SD_Card/GIT/AAP_Migration
    ansible-playbook playbooks/00_platform_setup.yml --syntax-check
    ```
  - Or set `ANSIBLE_CONFIG` explicitly:
    ```bash
    ANSIBLE_CONFIG=/run/media/sgallego/SD_Card/GIT/AAP_Migration/ansible.cfg \
    ansible-playbook /run/media/sgallego/SD_Card/GIT/AAP_Migration/playbooks/00_platform_setup.yml --syntax-check
    ```
  - Or set `ANSIBLE_ROLES_PATH`:
    ```bash
    ANSIBLE_ROLES_PATH=/run/media/sgallego/SD_Card/GIT/AAP_Migration/roles \
    ansible-playbook /run/media/sgallego/SD_Card/GIT/AAP_Migration/playbooks/00_platform_setup.yml --syntax-check
    ```

- “provided hosts list is empty”: expected for localhost-only playbooks like platform setup/preflight.

---

## Strategic enhancements for a 2.4 → 2.6 jump

To ensure the migration scripts don't time out or fail due to legacy metadata, incorporate these steps:

### Infrastructure readiness
- PostgreSQL 15 (AAP 2.6 requires it for external DBs)
- Database vacuuming:
  ```bash
  vacuumdb -h <db_host> -U postgres -d tower -zv
  ```
- User audit: unify email addresses across Controller and Hub

### Content & Execution Environments (EE)
- Ansible-Core 2.17 in AAP 2.6
- Rebuild EEs with Ansible Builder 3 and Python 3.11+

---

## Porting & deprecations

| Feature | Change in 2.5/2.6 | Action |
| --- | --- | --- |
| Jinja2 tests | `result | changed` deprecated | Update logic |
| include_tasks | No implicit attribute inheritance | Use explicit attributes or `block` |
| RBAC | Centralized in Platform Gateway | Reconfigure SSO at Gateway |
| EDA | DB migration unsupported | Fresh install/reconfigure |

---

## Upgrade process (sequential path)

1) Prepare 2.4: upgrade to latest 2.4, back up DB, vacuum
2) Transition to 2.5: define `[automationgateway]` in installer inventory, run setup, verify unified UI
3) Leap to 2.6: ensure PostgreSQL 15, run setup, verify services

---

## Post-upgrade verification

- Services:
  ```bash
  automation-controller-service status
  automation-gateway-service status
  ```
- Network mesh (receptor): ensure TCP 27199 connectivity
- EE testing: run “Hello World” on 2.6 EEs

---

## Summary checklist

- [ ] DB vacuumed on 2.4
- [ ] Users’ emails matched across Controller/Hub
- [ ] External DB upgraded to PostgreSQL 15
- [ ] EEs rebuilt with Python 3.11+
- [ ] Firewall port 27199 open for Mesh/Peers