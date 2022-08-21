# Init - RedHat family verison 8

Initialization of a Docker server with Ngnix Proxy Manager as a Reverse proxy system. This project will execute an Ansible CLI installation and 4 Ansible roles located in [ansible directory](ansible/roles).

> Defaults values can be customized in [vars file](ansible/group_vars/all/main.yaml)

## 🖥️ Operating system compatible

- RedHat Enterprise 8
- CentOS 8
- RockyLinux 8
- AlmaLinux 8

## 🚀 Get Started

```bash
git clone https://github.com/V1rtualAx3/init-rh-8.git
cd init-rh-8/

## for remote install
./init.sh -r

## for local install
./init.sh -l

## print help message
./init.sh -h
```

## :one: Prerequisites

Prerequisites role contains these features :
- Configuration of the default Timezone [ default: Europe/Paris ]
- Installation of several packages [ default: list in vars file ]
- Application of a default bashrc in skel and for root [ template in: 01_prerequisites/templates ]
- Installation of docker (container system) with containerd (container runtime) and docker-compose (container deployer)
- Activation of docker service

## :two: User creation

Creation of a default adminitrator user:
- Creation of a new adminitrator group [ default: adm ]
- Creation of a new administrator user with a autogenerate password, key pair and passphrase [ default: adm ]
- Add new adminitrator group to sudoers
- Add user key pair to authorized_keys file
- Deployment of a new SSHD configuration to denied password and force key pair authentification

## :three: Docker proxy

Deployment of a docker reverse proxy:
- Create of default docker data and manifest directory [ default: /data ]
- Deploy Nginx Proxy Manager template [ template in: 03_docker_proxy/templates ]
- Deploy Nginx Proxy Manager container

## :four: After run

Delete orginal account like ec2-user, almalinux, centos, etc:
- Creation of an admin directory [ default: /admin ]
- Creation of binary subdirectory in admin
- Deployment of after-run script template [ template in: 04_after_run/templates ]
- Deployment of after-run ansible playbook template [ template in: 04_after_run/templates ]
- Creation of a cron job to execute after-run script
- Execute auto reboot in 5 minutes
