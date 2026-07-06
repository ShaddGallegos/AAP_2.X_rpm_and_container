#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_ROOT}"

echo "Step 1/2: Generate group_vars/all.yml"
ansible-playbook scripts/prompt_group_vars_all.yml

echo
echo "Step 2/2: Generate group_vars/vault.yml"
ansible-playbook scripts/prompt_group_vars_vault.yml

echo
echo "Done. Encrypt vault file if not already encrypted:"
echo "  ansible-vault encrypt group_vars/vault.yml"
