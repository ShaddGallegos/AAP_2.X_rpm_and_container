# AAP 2.4 → 2.5 → 2.6 Migration Planning Document

## Objectives

- Upgrade Ansible Automation Platform from 2.4 → 2.5 → 2.6 in order.
- Produce evidence artifacts at each stage:
  - VMware snapshot name(s)
  - AAP backups
  - sosreport archives
  - Validation results (services + API reachability)
  - Human-readable stage reports
- Provide safe rollback options:
  - Revert VMware snapshots at decision points
  - Restore from installer backups if needed

## Scope assumptions

- AAP is running on VMware VMs managed by vCenter.
- Installer bundles for 2.4/2.5/2.6 are already staged on the target nodes under `/opt/aap/...`.
- You have API access and credentials to vCenter.

## Recommended staging & prerequisites

### Platform requirements

- Verify PostgreSQL 15 availability for the 2.6 stage (especially if using external DB).
- Confirm adequate disk space for:
  - backups
  - sosreport archives
  - installer working directories

### Identity & RBAC

- Ensure consistent email addresses across Controller/Hub prior to Unified Gateway migration.
- Plan and document SSO changes required at Gateway level.

### Execution Environments

- Rebuild and validate critical EEs for ansible-core 2.17 and modern Python.
- Test EE pulls from Hub and execution on execution nodes.

## Operational runbook (high-level)

1. Snapshot VMs (PRE 2.4)
2. Backup + sosreport at 2.4
3. Upgrade to 2.5
4. Validate 2.5
5. Snapshot VMs (PRE 2.6)
6. Backup + sosreport at 2.5
7. Upgrade to 2.6
8. Validate 2.6
9. Backup + sosreport at 2.6
10. Produce final sign-off report

## Automation deliverables in this repo

- `playbooks/migrate_24_25_26.yml`: end-to-end orchestrator
- `playbooks/05_pre_migration_healthcheck.yml`: pre-migration health check (psql version, legacy Jinja scan, podman images)
- Snapshots:
  - `playbooks/10_snapshot_24.yml`
  - `playbooks/50_snapshot_25.yml`
- Backups + sosreport:
  - `playbooks/20_backup_24.yml`
  - `playbooks/60_backup_25.yml`
  - `playbooks/85_backup_26.yml`
- Upgrades:
  - `playbooks/30_upgrade_24_to_25.yml`
  - `playbooks/70_upgrade_25_to_26.yml`
- Validation:
  - `playbooks/40_validate_25.yml`
  - `playbooks/80_validate_26.yml`
- Functional smoke tests:
  - `playbooks/45_smoke_test_25.yml`
  - `playbooks/82_smoke_test_26.yml`
- Rollback:
  - `playbooks/rollback_to_snapshot_24.yml`
  - `playbooks/rollback_to_snapshot_25.yml`
  - `playbooks/restore_from_backup.yml`

## Decision points

- After 2.5 upgrade + validation:
  - If validation fails: revert snapshot PRE 2.4.
- After 2.6 upgrade + validation:
  - If validation fails: revert snapshot PRE 2.6.

## Evidence & reporting

- Stage reports are written to `reports/`.
- Backup summaries are written per-host to `reports/backup_<stage>_<host>.txt`.
- sosreport archives are fetched to `sosreports/`.

## Functional smoke test requirements

The smoke tests use the Controller API and require:

- `aap_controller_url`
- `aap_api_token`

Optionally, to perform a real “job run” validation, set:

- `smoke_job_template_id` (an existing Job Template ID that is safe to run)

## Risk register (starter)

- External DB version mismatch (PostgreSQL < 15) blocks 2.6
- EE incompatibilities under ansible-core 2.17
- SSO/RBAC changes at Unified Gateway cause access issues
- Backup storage exhaustion

## Backout strategy

- Primary: VMware snapshot revert at decision points.
- Secondary: restore from installer backups using `playbooks/restore_from_backup.yml`.
