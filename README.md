# NixOS Configuration Files

Everything in this repo is fully declarative. You should be able to go from zero to OS in 15 minutes.

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

Adding new host:

Clone into host home dir (https://github.com/mjmaurer/infra.git)
Add PW to .vault-password
Install Ansible: https://docs.ansible.com/ansible/latest/installation_guide/installation_distros.html#installing-ansible-on-ubuntu
sudo apt upgrade ansible
copy .vault-password
ansible-galaxy install -r requirements.yaml
Create <machine_name> section in:
run.yaml
hosts.ini
roles/
host_vars/ (make sure to add correct username if not mjmaurer7)
bash playbook.sh <machine_name>
Vault:

nix-shell
adecrypt
aencrypt