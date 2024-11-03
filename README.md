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
# NixOS Configuration Files

Everything in this repo is fully declarative. You should be able to go from zero to OS in 15 minutes.

## Artwork

Contains various backgrounds I have collected over the years.

## Home

Dotfiles

## Machines

- Neptune (My main desktop)
- Saturn (A Purism Librem 15v3)

## System

Any configuration that will apply to all users on a machine usually hardware specific configuration.

# Install

_WARNING_ The following steps create an entire operating system.
This goes without saying but backup your data on the device you choose.

```sh
cd install
nix-build iso.nix
sudo dd if=result/<iso> of=/dev/<usb>
# Boot into nixos iso image on /dev/<usb>
# Configure networking
partition --device /dev/<harddrive> --bios ([l]egacy|[u]efi)
# Make personal changes to /mnt/etc/nixos
echo "<hostname>" >> /mnt/etc/nixos/hostname # Must match the name of the file in /machines
nixos-install
```
