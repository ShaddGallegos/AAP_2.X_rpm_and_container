#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANSIBLE_CONFIG="${PROJECT_ROOT}/ansible.cfg"
export ANSIBLE_CONFIG

run_playbook() {
  local pb="$1"
  shift || true
  echo
  echo "Running: ${pb} $*"
  echo
  ansible-playbook "${PROJECT_ROOT}/${pb}" "$@"
}

restore_menu() {
  while true; do
    echo
    echo "Restore Options"
    echo "1) Restore 2.6 RPM pre-2.6 containerized"
    echo "2) Restore 2.6 RPM pre-2.7 containerized"
    echo "3) Restore 2.6 containerized pre-2.7 containerized"
    echo "4) Restore 2.6 containerized pre-2.7 OpenShift"
    echo "5) Restore 2.6 containerized pre-2.6 OpenShift"
    echo "0) Back"
    read -rp "Select: " sel
    case "${sel}" in
      1) read -rp "Backup file path: " p; run_playbook playbooks/103_restore_26_rpm_pre_26_containerized.yml -e "aap_restore_from=${p}" --ask-vault-pass ;;
      2) read -rp "Backup file path: " p; run_playbook playbooks/94_restore_26_rpm_pre_27_containerized.yml -e "aap_restore_from=${p}" --ask-vault-pass ;;
      3) read -rp "Backup file path: " p; run_playbook playbooks/95_restore_26_containerized_pre_27_containerized.yml -e "aap_restore_from=${p}" --ask-vault-pass ;;
      4) read -rp "Backup file path: " p; run_playbook playbooks/104_restore_26_containerized_pre_27_openshift.yml -e "aap_restore_from=${p}" --ask-vault-pass ;;
      5) read -rp "Backup file path: " p; run_playbook playbooks/105_restore_26_containerized_pre_26_openshift.yml -e "aap_restore_from=${p}" --ask-vault-pass ;;
      0) return ;;
      *) echo "Invalid selection" ;;
    esac
  done
}

migration_menu() {
  while true; do
    echo
    echo "Migration Options"
    echo "1) 2.4 RPM -> 2.5 RPM -> 2.6 containerized"
    echo "2) 2.5 RPM -> 2.6 containerized (legacy export/import)"
    echo "3) 2.6 RPM -> 2.6 containerized"
    echo "4) 2.6 RPM -> 2.7 containerized"
    echo "5) 2.6 containerized -> 2.7 containerized"
    echo "6) 2.6 containerized -> 2.7 OpenShift"
    echo "7) 2.6 containerized -> 2.6 OpenShift"
    echo "0) Back"
    read -rp "Select: " sel
    case "${sel}" in
      1) run_playbook playbooks/migrate_24_25_26.yml --ask-vault-pass ;;
      2) run_playbook playbooks/migrate_25rpm_to_26containerized_legacy.yml --ask-vault-pass ;;
      3) run_playbook playbooks/migrate_26rpm_to_26containerized.yml --ask-vault-pass ;;
      4) run_playbook playbooks/migrate_26rpm_to_27containerized.yml --ask-vault-pass ;;
      5) run_playbook playbooks/migrate_26containerized_to_27containerized.yml --ask-vault-pass ;;
      6) run_playbook playbooks/migrate_26containerized_to_27openshift.yml --ask-vault-pass ;;
      7) run_playbook playbooks/migrate_26containerized_to_26openshift.yml --ask-vault-pass ;;
      0) return ;;
      *) echo "Invalid selection" ;;
    esac
  done
}

config_as_code_menu() {
  while true; do
    echo
    echo "Configuration as Code"
    echo "1) Generate config-as-code bundle"
    echo "2) Recreate environment from config-as-code defaults"
    echo "0) Back"
    read -rp "Select: " sel
    case "${sel}" in
      1) run_playbook playbooks/110_generate_config_as_code_bundle.yml --ask-vault-pass ;;
      2) run_playbook playbooks/111_recreate_environment_from_cac.yml --ask-vault-pass ;;
      0) return ;;
      *) echo "Invalid selection" ;;
    esac
  done
}

while true; do
  echo
  echo "AAP 2.X RPM and Container Operations"
  echo "1) Healthcheck and tuning"
  echo "2) Migrations and upgrades"
  echo "3) Restore from backup"
  echo "4) Configuration as code"
  echo "0) Exit"
  read -rp "Select: " sel
  case "${sel}" in
    1) run_playbook playbooks/06_aap_healthcheck.yml ;;
    2) migration_menu ;;
    3) restore_menu ;;
    4) config_as_code_menu ;;
    0) exit 0 ;;
    *) echo "Invalid selection" ;;
  esac
done
