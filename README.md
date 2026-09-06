# ☁️ OVH Cloud Dev Environment

A **code-server** (VS Code in the browser) instance on OVH Public Cloud that you can spin up to work and tear down when done. It automatically backs up your data to Object Storage between sessions.

> 💡 **Note:** See [`ARCHITECTURE.md`](ARCHITECTURE.md) for the reasoning behind each design choice.

---

## ✨ Features

### 🛠 Core

- **code-server:** Code directly in your browser (pinned version + checksum verification).
- **Ephemeral Lifecycle:** Use `make create` and `make destroy`. The instance and public IPs are freshly recreated each cycle.
- **Backup & Restore:** Automatically runs `tar` to OVH Object Storage on `create` (restore) and `destroy` (backup).
- **Optional Dev Tooling:** Use the Ansible `customization` role to ship dev tools with feature-toggling via `group_vars/vars.yml`.

### 🔒 Security & Hardening

- **HTTPS:** Secured with an Nginx reverse proxy and Let's Encrypt certificates.
- **IP Filtering:** `nftables` allowlists per port (SSH / HTTP / HTTPS).
- **System Hardening:**:
  - SSH key-only authentication.
  - `fail2ban` on SSH and code-server logins.
  - Nginx rate-limiting on the `/login` route.
  - Unattended security upgrades, `sysctl` tightening, and rare-protocol module blacklisting.
- **Secrets Management:** Secrets are safely stored in an Ansible Vault-encrypted file (`group_vars/vault.yml`), while non-secrets live in `group_vars/vars.yml`.

### 🌐 Networking

- **Dual-stack IPv4 + IPv6:** Terraform manages your OVH DNS `A` and `AAAA` records automatically.

---

## 🚀 Setup

### Prerequisites

Before you begin, ensure you have the following:

- **Terraform** >= 1.5
- **Ansible** >= 2.15
- An **OVH Public Cloud** project
- A **domain name**
- A **local SSH keypair** (e.g., `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519`)

### 1. OVH Credentials

You will need three sets of credentials (see `ARCHITECTURE.md` for details). Export them in your terminal (or use `~/.ovh.conf` for the OVH API):

```bash
# 1. OpenStack User (Manager → Public Cloud → Project → Users & Roles → Create user)
export OS_USERNAME="..."
export OS_PASSWORD="..."
export OS_USER_DOMAIN_NAME="Default"

# 2. OVH API App (https://api.ovh.com/createToken/)
# Rights: /cloud/project/* (and GET/POST/PUT/DELETE /domain/zone/* if manage_dns = true)
export OVH_ENDPOINT="ovh-eu"
export OVH_APPLICATION_KEY="..."
export OVH_APPLICATION_SECRET="..."
export OVH_CONSUMER_KEY="..."

# 3. S3 Credentials (for Terraform state: Manager → Public Cloud → Project → Storage → Object Storage → Users tab)
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
```

### 2. Terraform State Bucket

Create an Object Storage bucket manually via the OVH Manager to store your Terraform state.

### 3. Bootstrap (Run Once)

```bash
cd terraform-bootstrap
cp backend.tfvars.example backend.tfvars      # Fill in your state bucket name
cp terraform.tfvars.example terraform.tfvars  # Fill in ovh_project_id and ssh key path
cd .. && make bootstrap
```

### 4. Ephemeral Config

```bash
cd terraform-ephemeral
cp backend.tfvars.example backend.tfvars      # Use the same state bucket, but a different key
cp terraform.tfvars.example terraform.tfvars  # Adjust your variables as needed
cd ..
```

### 5. Ansible Config & Secrets

```bash
# 1. Setup variables
cp ansible/group_vars/vars.yml.example ansible/group_vars/vars.yml
# Edit vars.yml: add domain_name, letsencrypt_email, backup_paths, backup_excludes

# 2. Setup secrets
cp ansible/group_vars/vault.yml.example ansible/group_vars/vault.yml
# Fill in the manual secrets inside vault.yml, then encrypt it:
ansible-vault encrypt ansible/group_vars/vault.yml

# 3. Save your vault password securely
read -s -p "Vault password: " PASS && echo && printf '%s' "$PASS" > .vault_pass && chmod 600 .vault_pass && unset PASS
```

### 6. Usage

```bash
make create    # Provisions the instance, restores the last backup, and is ready to use
make destroy   # Backs up the current state and destroys the instance
```

### 7. Connect

`make create` generates a fresh code-server password on every run and stores it in the Ansible vault. To retrieve your credentials:

```bash
make code-server-url       # Prints https://<domain_name>/
make code-server-password  # Prints the password (pipe it to your clipboard)
```

---

## ⚠️ Troubleshooting

| Error / Issue | Solution |
| ------------- | -------- |
| **"No suitable endpoint could be found in the service catalog"** | `compute_region` / `object_storage_region` use different naming conventions (e.g., `GRA11` vs `GRA`). Ensure they match what your OVH project actually uses. |
| **`OverQuota` on `security_group`** | New OVH accounts often have a quota of 0. Leave `create_security_group = false` (default) or add a payment method to raise your quota. |
| **"Neither a boot device, image ID, or image name..."** | `instance_image` must exactly match an **active** image name for your region. |
| **Let's Encrypt fails on `make create`** | Public IPs change every cycle. Your DNS records must update before Ansible runs the nginx role. Use `manage_dns = true` or update manually. *(Tip: If only IPv6 fails, remove the AAAA record).* |
| **`make` keeps asking for the vault password** | Make sure you created the `.vault_pass` file (see Step 5). |
| **`OVHcloud API error (403) ... not been granted` on DNS** | Your API token lacks `/domain/zone/*` rights. Recreate the token or set `manage_dns = false`. |

---

## 📄 License

**GNU Affero General Public License v3.0**
See the [LICENSE](LICENSE) file for details.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. It is distributed WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
