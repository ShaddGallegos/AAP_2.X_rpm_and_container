#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
export ANSIBLE_CONFIG="$ROOT_DIR/ansible.cfg"
export ANSIBLE_ROLES_PATH="$ROOT_DIR/roles"

VENV_DIR="${AAP_VENV_DIR:-$ROOT_DIR/.venv}"
ANSIBLE_PLAYBOOK_BIN=""

ensure_ansible_tooling() {
  if command -v ansible-playbook >/dev/null 2>&1 && ansible-playbook --version >/dev/null 2>&1; then
    ANSIBLE_PLAYBOOK_BIN="$(command -v ansible-playbook)"
    return
  fi

  if [[ "${AAP_AUTO_VENV:-1}" != "1" ]]; then
    echo "ansible-playbook not found in PATH and AAP_AUTO_VENV is disabled"
    exit 1
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required to create a virtual environment"
    exit 1
  fi

  if [[ ! -d "$VENV_DIR" ]]; then
    echo "Creating virtual environment at $VENV_DIR"
    python3 -m venv "$VENV_DIR"
  fi

  # shellcheck disable=SC1090
  source "$VENV_DIR/bin/activate"
  hash -r

  if ! command -v ansible-playbook >/dev/null 2>&1 || ! ansible-playbook --version >/dev/null 2>&1; then
    echo "Installing Ansible tooling into $VENV_DIR"
    python -m pip install --upgrade pip >/dev/null
    pip install ansible ansible-lint yamllint >/dev/null
    hash -r
  fi

  if [[ -x "$VENV_DIR/bin/ansible-playbook" ]]; then
    ANSIBLE_PLAYBOOK_BIN="$VENV_DIR/bin/ansible-playbook"
  else
    ANSIBLE_PLAYBOOK_BIN="$(command -v ansible-playbook)"
  fi
}

ensure_ansible_tooling

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
  "$ANSIBLE_PLAYBOOK_BIN" -i "$INVENTORY" "$pb" --syntax-check
done

echo "All playbook syntax checks passed."
