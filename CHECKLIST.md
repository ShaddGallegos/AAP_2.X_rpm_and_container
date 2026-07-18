# AAP_2.X_rpm_and_container — Quick Checklist

Purpose: Playbooks and scripts to migrate/upgrade/backup Red Hat Ansible Automation Platform (AAP) 2.x RPM/container stages.

Prerequisites
- Python 3, `pip3` available
- `ansible-core` and `ansible-galaxy` on PATH
- Container runtime if using containerized flows (`podman` or `docker`)

Quick setup
1. Change to the project folder:

```bash
cd AAP_2.X_rpm_and_container
```

2. Install Ansible collections (if required):

```bash
ansible-galaxy collection install -r requirements.yml
```

3. (Optional) Install Python deps if a `requirements.txt` exists:

```bash
pip3 install -r requirements.txt
```

4. Validate and run the main site/setup playbook:

```bash
ansible-playbook --syntax-check setup-site.yml
ansible-playbook setup-site.yml
```

Verify
- Check `logs/` for playbook outputs and any error files.
- Inspect `inventories/` and `group_vars/` for expected values.

Rollback / cleanup
- Use documented backup/restore playbooks in `playbooks/` or consult `docs/` for scenario-specific rollback steps.

Notes
- Read `README.md` and `docs/` for scenario matrix and upgrade paths before running.
