# Personal Infrastructure

## Overview

- Nix Package Manager / Home-Manager does most of the heavy lifting for user configuration (see [nixpkgs/README.md](nixpkgs/README.md))
- Ansible is used to install software on remote hosts, but I'm actively moving to NixOS (see `nixos` branch)

## Adding new host / user:

- Clone this repo into your user's home directory
- Add PW to `.vault-password`
- [Install Ansible](https://docs.ansible.com/ansible/latest/installation_guide/installation_distros.html#installing-ansible-on-ubuntu)
- `sudo apt upgrade ansible `
- `ansible-galaxy install -r requirements.yaml`
- Create <machine_name> section in:
  - run.yaml
  - hosts.ini
  - roles/
  - host_vars/ (make sure to add correct username if not mjmaurer7)
- `bash playbook.sh <machine_name>`

## Switch to new Home Manager generation:

- `hmswitch`

## Encrypting / Descrypting Ansible Vault:

- `nix-shell`
- `adecrypt`
- `aencrypt`
