# Enterprise Red Hat Ansible Automation Platform (AAP) Tuning & Audit Suite

This enterprise-grade automation toolkit maps infrastructure status, audits vulnerabilities, reviews resource limits, and enforces system optimization profiles across **Red Hat Ansible Automation Platform (AAP) 2.4, 2.5, 2.6, and 2.7** environments running on RHEL architectures.

## Files

- vars.yml: User-configurable variables for tuning and toggles.
- execution-environment.yml: Ansible Builder v3 Execution Environment specification.
- aap_production_orchestrator.yml: Primary orchestration playbook.

## Quick Start

1. Review `vars.yml` and adjust values as needed for your environment.
2. To display the built-in help/info without making changes run:

```bash
ansible-playbook aap_production_orchestrator.yml -e show_help=true
```

3. To run in check (dry-run) mode:

```bash
ansible-playbook -i your_hosts_inventory aap_production_orchestrator.yml --check
```

4. To execute against your inventory (apply changes):

```bash
ansible-playbook -i your_hosts_inventory aap_production_orchestrator.yml
```

## Building the Execution Environment

1. Authenticate with Red Hat registry if using Red Hat base images:

```bash
podman login registry.redhat.io
```

2. Build the EE image with Ansible Builder 3:

```bash
ansible-builder build --tag your_private/ aap-tuning-ee:1.0 --verbosity 3
```

## Notes

- This toolkit assumes RHEL hosts with `dnf`/`rpm` toolchains.
- Review and test on non-production systems before applying to production.
