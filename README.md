# ansible-homelab
ansible configuration for home servers

# windows network settings
type below command in command line or in Start > Run
`ncpa.cpl`
disable IP6 for Ethernet connections

# hyper-V config
Create External LAN network, it will be used for all VMs

![alt text](image.png)

![alt text](image-1.png)

# ssh key
ssh server will be configured to use only ed25519 keys. other keys will be disabled
`
ssh-keygen -t ed25519 -C "alex.gluhov@outlook.com"
`

# wsl
below is for Almalinux-9, but you can install other wsl distribution
* list all available wsl distributions. pick any for installation
  `wsl --list --online`
* install wsl distribution
  `wsl --install Almalinux-9`
* backup
  `wsl --export AlmaLinux-9 E:\backup\vm_backups\wsl\AlmaLinux9.tar`

# wsl initial config
install python 3.12
```
sudo dnf intall python3.12 python3.12-pip make
```
install uv (for current user) using pip
```
python3.12 -m pip install --user uv
```

# ansible
Install required collections
```
uv run ansible-galaxy collection install -r collections/requirements.yaml -p collections/
```

Run playbook in dev only
```
uv run ansible-playbook -i inventory/hosts.yaml playbooks/site.yaml -vv -K --limit dev
```
Dry run playbook in dev (no changes applied)
```
uv run ansible-playbook -i inventory/hosts.yaml playbooks/site.yaml -vv -K --limit dev --check --diff
```

# playbook examples
Common
```
uv run ansible-playbook -i inventory/hosts.yaml playbooks/common.yaml -vv -K
```
PostgreSQL
```
uv run ansible-playbook -i inventory/hosts.yaml playbooks/postgresql.yaml -vv -K
```
PgAdmin
```
uv run ansible-playbook -i inventory/hosts.yaml playbooks/pgadmin.yaml -vv -K
```
Gitea
```
uv run ansible-playbook -i inventory/hosts.yaml playbooks/gitea.yaml -vv -K
```

Site (all roles, dev only)
```
uv run ansible-playbook -i inventory/hosts.yaml playbooks/site.yaml -vv -K --limit dev
```

# podman
list all containers
```
cd /tmp && sudo -u podman -H bash -lc 'uid=$(id -u); XDG_RUNTIME_DIR=/run/user/$uid DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$uid/bus podman ps -a'
```

filter to pgadmin container
```
cd /tmp && sudo -u podman -H bash -lc 'uid=$(id -u); XDG_RUNTIME_DIR=/run/user/$uid DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$uid/bus podman ps -a --filter name=pgadmin'
```
