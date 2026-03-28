---
description: Generate an SSH deploy key in ~/.ssh/ named after the current git repo
---

### `/deploy-key`

Generate an ED25519 SSH deploy key for the current git repository.

## Instructions

### 1. Determine the repository name

Run `basename $(git rev-parse --show-toplevel)` to get the current git repository directory name.

### 2. Generate the deploy key

Run `ssh-keygen -t ed25519 -f ~/.ssh/<repo-name>_deploy_key -N ''` where `<repo-name>` is the name from step 1.

If the key already exists, **stop** and warn the user. Do NOT overwrite it.

### 3. Show the public key

Display the contents of `~/.ssh/<repo-name>_deploy_key.pub` so the user can copy it to their Git hosting provider.

### 4. Summary

Tell the user:
- Private key: `~/.ssh/<repo-name>_deploy_key`
- Public key: `~/.ssh/<repo-name>_deploy_key.pub`
- Remind them to add the public key as a deploy key in their repository settings
