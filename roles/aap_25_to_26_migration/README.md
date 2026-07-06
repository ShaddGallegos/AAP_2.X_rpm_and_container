# Role: aap_25_to_26_migration

This role performs an end-to-end migration from AAP 2.5 RPM to AAP 2.6 Containerized.

## What it does

1. Optionally runs `setup.sh -b` backup on the old RPM host.
2. Optionally exports old controller configuration using `infra.controller_configuration.dispatch`.
3. Renders installer inventory from template for `single_node` or `growth` topology.
4. Copies rendered inventory to new host installer directory.
5. Runs AAP 2.6 `setup.sh -i inventory` on the new host.
6. Waits for gateway health endpoint.
7. Optionally imports exported data into the new controller.
8. Verifies gateway health, controller API ping, and key containers.

## UX features

- `aap_25_to_26_migration_run_preflight`: checks installer paths, `setup.sh`, and Podman before migration.
- `aap_25_to_26_migration_dry_run`: skips destructive actions (backup/install/import) while still validating preflight and rendering inventory.
- Strict role variable namespace: all role defaults use `aap_25_to_26_migration_*`.

## Requirements

- Collections installed:
  - `infra.controller_configuration`
  - `infra.ah_configuration`
  - `infra.eda_configuration`
  - `infra.ee_utilities`
- Control node can SSH to both old and new hosts.
- Installer extracted on old and new hosts at configured paths.

## Minimal usage

```yaml
---
- hosts: localhost
  connection: local
  roles:
    - role: aap_25_to_26_migration
```

Use `/home/sgallego/Git/RHEL_AAP_Upgrade/group_vars/all.yml.example` as your starting point.

## Artifacts

- Rendered inventory: `{{ aap_25_to_26_migration_rendered_inventory_path }}`
- Exported API configuration: `{{ aap_25_to_26_migration_export_dir }}`
- Optional fetched backup archive: `{{ aap_25_to_26_migration_backup_local_dir }}`

## Rollback guidance

1. Keep old RPM instance intact until validation passes on 2.6.
2. If cutover fails, restore service on old host and re-run migration after fixes.
3. Use the generated backup tarball from `setup.sh -b` to restore RPM platform state if needed.

## Smoke testing

From project root:

```bash
./scripts/smoke_test.sh
```
