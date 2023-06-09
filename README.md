TODO: maybe have to create docker user: https://github.com/ironicbadger/infra/issues/6

TODO: run localhost bootstrap then reg playbook (see chatgpt):
- Confirm dependencies of both
- See if 

Steps:
- Clone on host (https://github.com/mjmaurer/infra.git)
- Add PW to .vault-password
- Install Ansible: https://docs.ansible.com/ansible/latest/installation_guide/installation_distros.html#installing-ansible-on-ubuntu
- sudo apt upgrade ansible 
- copy .vault-password
- make reqs
- make 'host'