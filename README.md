Adding new host:
- Clone into host home dir (https://github.com/mjmaurer/infra.git)
- Add PW to .vault-password
- Install Ansible: https://docs.ansible.com/ansible/latest/installation_guide/installation_distros.html#installing-ansible-on-ubuntu
- sudo apt upgrade ansible 
- copy .vault-password
- ansible-galaxy install -r requirements.yaml
- Create <machine_name> section in:
  - run.yaml
  - hosts.ini
  - roles/
  - host_vars/ (make sure to add correct username if not mjmaurer7)
- bash playbook.sh <machine_name>

Vault:
- nix-shell
- adecrypt 
- aencrypt 