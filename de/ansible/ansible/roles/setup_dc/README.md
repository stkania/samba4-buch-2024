##Role Name

This role will setup a domain for a Samba-Active-Directory. The setup will also install and configure the bind9 as DNS-Server. You can use it to setup just one DC or more. The first time you use the playbook the domain provision will be executed, this will be your first DC. After the first run you can join the other DCs with this playbook. All DCs will use bind9 as the DNS-server

##Requirements

This role requires an inventory with: 
- A group for the first DC. This group will be used to deside the special steps for the first DC for example the provision.
- A grou for all the other DCs comming after the first DC. This group is used to setup special task for any other DC like the join.
- On entry for every DC in one of the groups.

Here you see an example of an inventory-file:
```
[samba_dc]
addc-01
addc-02

[first_dc]
addc-01

[next_dc]
addc-02

[samba_dc:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_user=ansible
ansible_become=yes
```
Running the playbook the first time on any of the DCs you have to disable the last two lines so the playbook can run as root. To start the playbook as root do a:
```
ansible-playbook setup-dc.yml -u root --ask-pass
```

Root-login via ssh must be possible. The ssh-root login will be revoked at the end of the role.

An Ansible-user with ssh public-key without passphrase.
##Role Variables

All variables are defined in defaults/main.yml. Change to your needs 

##Supported Distributions
Debian 10 if you want to use it with Ubuntu you must take care of apparmor!

##Description
The role is depending on the two groups first_dc and other_dc to deside what to do. 
- First the ansible user will be created on the host und sudo is installed
- Setting up the repository for the samba-packages from Louis van Belle. (Thank you Louis for your work)
- Installing all needed packages (takes some time)
- Depending on the group the provision or the join will be done
- Configuring bind9 and check filesystem permissions
- Setting up systemd to start samba-ad-dc
- The ntp-server will get a new configuration from file files/ntp.conf
- last step is rebooting the system 

##Example Playbook

Here is an example for the playbook of the first DC
```
---
- hosts: first_dc
  roles:
    - setup_dc
```
And the script for any other DC
```
---
- hosts: next_dc
  roles:
    - setup_dc
```

##Author Information
Stefan Kania stefan@kania-online.de
