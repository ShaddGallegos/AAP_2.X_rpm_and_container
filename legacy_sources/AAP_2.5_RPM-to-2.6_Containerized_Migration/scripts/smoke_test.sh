#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

printf "[1/3] Syntax check role entrypoint...\n"
ansible-playbook --syntax-check migrate_aap_25_to_26.yml

printf "[2/3] Lint project role/playbook...\n"
ansible-lint migrate_aap_25_to_26.yml \
  roles/aap_25_to_26_migration/tasks/main.yml \
  roles/aap_25_to_26_migration/tasks/validate.yml \
  roles/aap_25_to_26_migration/meta/main.yml

printf "[3/3] Render smoke inventories...\n"
ansible-playbook tests/smoke_render_inventory.yml

printf "Smoke test passed.\n"
