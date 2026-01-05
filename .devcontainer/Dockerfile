FROM ghcr.io/almalinux/9-base:9.7

RUN dnf update -y && \
    dnf install -y \
        xorriso \
        pykickstart \
        git \
        python3.12 \
        python3.12-pip && \
    python3.12 -m pip install --upgrade pip setuptools wheel && \
    python3.12 -m pip install uv && \
    dnf clean all && \
    groupadd --gid 1000 vscode && \
    useradd --uid 1000 --gid 1000 -m -s /bin/bash vscode


ENV ANSIBLE_CONFIG=/workspaces/ansible-homelab/ansible.cfg