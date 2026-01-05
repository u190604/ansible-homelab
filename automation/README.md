# Hyper-V Setup Script

This folder contains `hyperv-setup.ps1`, a PowerShell script that enables Hyper-V on Windows 11 (including management tools), prepares storage paths, and creates or updates a Generation 2 VM with configurable CPU, memory, networking, VHDX, and attached ISO. The script now prompts for the VM name and ISO path if they are not provided in advance.

## Run

Run from an elevated PowerShell session:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; ./hyperv-setup.ps1
```

# Custom installation ISO (Devcontainer)
To automate OS installation we can use kickstart file `ks.cfg`.
Use the devcontainer (already has `xorriso`) to generate the custom ISO from a local ISO file.
use `ksvalidator` to validate kickstart file
```
ksvalidator /workspaces/ansible-homelab/automation/alma-iso/ks.cfg
```

Download the AlmaLinux ISO into the workspace:
```
curl -L -o /workspaces/ansible-homelab/automation/alma-iso/source.iso \
  https://mirror.2degrees.nz/almalinux/9.7/isos/x86_64/AlmaLinux-9.7-x86_64-minimal.iso
```

Or copy a local download into the workspace (example path shown):
```
cp C:\Users\aglu\Downloads\AlmaLinux-9.7-x86_64-dvd.iso /workspaces/ansible-homelab/automation/alma-iso/source.iso
```

Run the build inside the devcontainer:
```
cd /workspaces/ansible-homelab
VOLUME_LABEL="CUSTOM_ALMA" ./automation/build-alma-iso.sh \
  ./automation/alma-iso/source.iso \
  ./automation/alma-iso/custom_alma.iso
```
