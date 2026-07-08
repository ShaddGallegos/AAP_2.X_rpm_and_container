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

usage() {
  cat <<'USAGE'
Usage:
  scripts/validate_scenario_chain.sh <scenario>

Examples:
  scripts/validate_scenario_chain.sh 26rpm_to_27containerized
  AAP_INVENTORY=inventories/production.ini scripts/validate_scenario_chain.sh 26containerized_to_27openshift

Supported scenarios:
  healthcheck
  24rpm_to_25rpm_to_26containerized
  legacy_25rpm_to_26containerized
  26rpm_to_26containerized
  26rpm_to_27containerized
  26containerized_to_27containerized
  26containerized_to_27openshift
  26containerized_to_26openshift
  generate_config_as_code
  recreate_environment_from_cac
USAGE
}

if [[ ${1:-} == "" || ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi

SCENARIO="$1"
INVENTORY="${AAP_INVENTORY:-inventories/production.ini}"
VARS_FILE="group_vars/all.yml"

if [[ ! -f "$INVENTORY" ]]; then
  echo "Inventory not found: $INVENTORY"
  exit 1
fi

if [[ ! -f "$VARS_FILE" ]]; then
  echo "Required vars file not found: $VARS_FILE"
  exit 1
fi

ensure_ansible_tooling

get_var_value() {
  local key="$1"
  awk -F':' -v k="$key" '
    $1 ~ "^[[:space:]]*"k"[[:space:]]*$" {
      v=$0
      sub(/^[^:]*:[[:space:]]*/, "", v)
      sub(/[[:space:]]+#.*$/, "", v)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
      gsub(/^"|"$/, "", v)
      gsub(/^\047|\047$/, "", v)
      print v
      exit
    }
  ' "$VARS_FILE"
}

require_vars() {
  local missing=0
  for key in "$@"; do
    local val
    val="$(get_var_value "$key")"
    if [[ -z "$val" ]]; then
      echo "Missing required variable in $VARS_FILE: $key"
      missing=1
    fi
  done
  if [[ $missing -ne 0 ]]; then
    exit 1
  fi
}

PLAYBOOKS=()
case "$SCENARIO" in
  healthcheck)
    PLAYBOOKS=("playbooks/06_aap_healthcheck.yml")
    ;;
  24rpm_to_25rpm_to_26containerized)
    require_vars aap24_installer_dir aap25_installer_dir aap26_installer_dir
    PLAYBOOKS=(
      "playbooks/00_platform_setup.yml"
      "playbooks/05_pre_migration_healthcheck.yml"
      "playbooks/10_snapshot_24.yml"
      "playbooks/20_backup_24.yml"
      "playbooks/30_upgrade_24_to_25.yml"
      "playbooks/50_snapshot_25.yml"
      "playbooks/60_backup_25.yml"
      "playbooks/70_upgrade_25_to_26.yml"
      "playbooks/80_validate_26.yml"
    )
    ;;
  legacy_25rpm_to_26containerized)
    require_vars aap25_installer_dir aap26_installer_dir
    PLAYBOOKS=(
      "playbooks/60_backup_25.yml"
      "playbooks/98_upgrade_25_rpm_to_26_containerized_legacy.yml"
      "playbooks/80_validate_26.yml"
      "playbooks/82_smoke_test_26.yml"
    )
    ;;
  26rpm_to_26containerized)
    require_vars aap26_installer_dir aap26_installer_inventory_rpm_to_containerized
    PLAYBOOKS=(
      "playbooks/89_backup_26_rpm_pre_26_containerized.yml"
      "playbooks/100_upgrade_26_rpm_to_26_containerized.yml"
      "playbooks/103_restore_26_rpm_pre_26_containerized.yml"
    )
    ;;
  26rpm_to_27containerized)
    require_vars aap26_installer_dir aap27_installer_dir aap27_installer_inventory_rpm_to_containerized
    PLAYBOOKS=(
      "playbooks/87_backup_26_rpm_pre_27_containerized.yml"
      "playbooks/92_upgrade_26_rpm_to_27_containerized.yml"
      "playbooks/94_restore_26_rpm_pre_27_containerized.yml"
    )
    ;;
  26containerized_to_27containerized)
    require_vars aap26_installer_dir aap27_installer_dir aap27_installer_inventory_containerized_to_containerized
    PLAYBOOKS=(
      "playbooks/88_backup_26_containerized_pre_27_containerized.yml"
      "playbooks/93_upgrade_26_containerized_to_27_containerized.yml"
      "playbooks/95_restore_26_containerized_pre_27_containerized.yml"
    )
    ;;
  26containerized_to_27openshift)
    require_vars aap26_installer_dir aap27_openshift_installer_dir aap27_openshift_installer_inventory_containerized_to_openshift
    PLAYBOOKS=(
      "playbooks/91_backup_26_containerized_pre_27_openshift.yml"
      "playbooks/101_upgrade_26_containerized_to_27_openshift.yml"
      "playbooks/104_restore_26_containerized_pre_27_openshift.yml"
    )
    ;;
  26containerized_to_26openshift)
    require_vars aap26_installer_dir aap26_openshift_installer_dir aap26_openshift_installer_inventory_containerized_to_openshift
    PLAYBOOKS=(
      "playbooks/96_backup_26_containerized_pre_26_openshift.yml"
      "playbooks/102_upgrade_26_containerized_to_26_openshift.yml"
      "playbooks/105_restore_26_containerized_pre_26_openshift.yml"
    )
    ;;
  generate_config_as_code)
    PLAYBOOKS=("playbooks/110_generate_config_as_code_bundle.yml")
    ;;
  recreate_environment_from_cac)
    PLAYBOOKS=("playbooks/111_recreate_environment_from_cac.yml")
    ;;
  *)
    echo "Unsupported scenario: $SCENARIO"
    usage
    exit 1
    ;;
esac

echo "Scenario: $SCENARIO"
echo "Inventory: $INVENTORY"
echo "Playbooks to syntax-check: ${#PLAYBOOKS[@]}"

for pb in "${PLAYBOOKS[@]}"; do
  if [[ ! -f "$pb" ]]; then
    echo "Missing playbook: $pb"
    exit 1
  fi
  echo "[syntax-check] $pb"
  "$ANSIBLE_PLAYBOOK_BIN" -i "$INVENTORY" "$pb" --syntax-check
done

echo "Scenario chain validation passed for: $SCENARIO"
