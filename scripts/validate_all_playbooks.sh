#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "ansible-playbook not found in PATH"
  exit 1
fi

INVENTORY="${AAP_INVENTORY:-inventories/production.ini}"

if [[ ! -f "$INVENTORY" ]]; then
  echo "Inventory not found: $INVENTORY"
  exit 1
fi

mapfile -t PLAYBOOKS < <(find playbooks -maxdepth 1 -type f -name "*.yml" | sort)

if [[ ${#PLAYBOOKS[@]} -eq 0 ]]; then
  echo "No playbooks found under playbooks/"
  exit 1
fi

echo "Validating ${#PLAYBOOKS[@]} playbooks using inventory: $INVENTORY"

for pb in "${PLAYBOOKS[@]}"; do
  echo "[syntax-check] $pb"
  ansible-playbook -i "$INVENTORY" "$pb" --syntax-check
done

echo "All playbook syntax checks passed."
