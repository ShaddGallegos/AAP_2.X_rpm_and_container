# AAP 2.4 → 2.5 → 2.6 Migration Checklist

## Before you start

- [ ] Confirm you are on latest AAP 2.4 z-stream
- [ ] Confirm DB requirements (AAP 2.6 requires PostgreSQL 15)
- [ ] Ensure execution environments are compatible (AAP 2.6 / ansible-core 2.17)
- [ ] Ensure vCenter access available for snapshots
- [ ] Confirm maintenance window + rollback decision points
- [ ] Create `group_vars/all.yml` from `group_vars/all.yml.example` (store secrets in Vault)
- [ ] Install required collections: `ansible-galaxy collection install -r requirements.yml`

## Stage 2.4 (baseline)

- [ ] Run pre-migration health check: `playbooks/05_pre_migration_healthcheck.yml`
- [ ] Run VMware snapshot: `playbooks/10_snapshot_24.yml`
- [ ] Run SOS + backup: `playbooks/20_backup_24.yml`
- [ ] Capture baseline validation evidence (API/service checks)

## Upgrade to 2.5

- [ ] Run upgrade: `playbooks/30_upgrade_24_to_25.yml`
- [ ] Validate 2.5: `playbooks/40_validate_25.yml`
- [ ] Functional smoke test 2.5: `playbooks/45_smoke_test_25.yml`
- [ ] If failed: rollback with `playbooks/rollback_to_snapshot_24.yml`

## Stage 2.5 (pre-2.6)

- [ ] Run VMware snapshot: `playbooks/50_snapshot_25.yml`
- [ ] Run SOS + backup: `playbooks/60_backup_25.yml`

## Upgrade to 2.6

- [ ] Run upgrade: `playbooks/70_upgrade_25_to_26.yml`
- [ ] Validate 2.6: `playbooks/80_validate_26.yml`
- [ ] Functional smoke test 2.6: `playbooks/82_smoke_test_26.yml`
- [ ] If failed: rollback with `playbooks/rollback_to_snapshot_25.yml`

## Stage 2.6 (final)

- [ ] Run SOS + backup: `playbooks/85_backup_26.yml`
- [ ] Review reports in `reports/`

## Sign-off

- [ ] Controller works: login + `/api/v2/ping/` returns 200
- [ ] Hub works (if used): API reachable
- [ ] Gateway works (if used): UI reachable and SSO configured
- [ ] Execution nodes connected (mesh)
- [ ] Sample automation run succeeded
