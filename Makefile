ping:
	uv run ansible all -m ping -K

addcollections:
	uv run ansible-galaxy collection install -r collections/requirements.yaml -p collections/
