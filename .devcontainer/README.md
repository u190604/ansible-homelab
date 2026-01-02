Devcontainer setup for using the Codex VS Code extension inside the container.

What the container includes

- Base image: `ghcr.io/almalinux/9-base:9.7`.
- Installed tools: `git`, `python3.12`, `python3.12-pip`, `uv`.
- ansible packages are installed via `uv sync`
- Container user: `vscode` (uid/gid 1000).

Devcontainer settings

- Workspace: `/workspaces/ansible-homelab`.
- User: `vscode`.
- `postStartCommand` creates `/home/vscode/.codex` and runs `uv` commands to sync repo in the workspace.
- Forwarded port: `1455`.
- VS Code extensions: `ms-python.python`, `openai.chatgpt`.

Codex config mount

The current `devcontainer.json` bind-mounts the Codex config from a Windows host path. If you are on Linux/macOS, switch it to `HOME`.

Windows:

```
"mounts": [
  "source=${env:USERPROFILE}\\.codex,target=/home/vscode/.codex,type=bind,consistency=cached"
]
```

Rebuild / reopen container

- From the Command Palette: "Dev Containers: Rebuild Container" (or "Reopen in Container").
- Using the `devcontainer` CLI (if installed):

```bash
devcontainer rebuild --workspace-folder .
```
