# OVH Cloud Dev Environment

A code-server (VS Code in the browser) instance on OVH Public Cloud that
you spin up to work and tear down when done, backing up your data to
Object Storage in between. See [ARCHITECTURE.md](ARCHITECTURE.md) for the
why behind each design choice.

## Features

- **code-server**: VS Code in the browser, pinned version installed from
  the official `.deb` with checksum verification, password auth, bound to
  localhost behind nginx.
- **HTTPS**: nginx reverse proxy, Let's Encrypt certificate via the ACME
  HTTP-01 webroot challenge, auto-renewal with an nginx-reload deploy hook.
- **Dual-stack IPv4 + IPv6**: nginx listens on both; optional Terraform
  management of the OVH DNS `A`/`AAAA` records.
- **IP filtering**: nftables allowlists per port (SSH/HTTP/HTTPS), separate
  IPv4 and IPv6 CIDR lists, plus the mandatory ICMPv6/NDP rules. Optionally
  mirrored at the OpenStack layer via a security group.
- **Hardening**: SSH key-only (no root, no password), fail2ban on SSH and
  on the code-server login, nginx rate-limit on `/login`, unattended
  security upgrades, sysctl tightening, rare-protocol module blacklist.
- **Ephemeral lifecycle**: `make create` / `make destroy`; the instance and
  its public IPs are recreated each cycle, nothing stateful lives in the
  ephemeral Terraform stack.
- **Backup / restore**: `tar` (with exclude list) to OVH Object Storage
  (rclone over Swift); restore only writes back allow-listed paths. Runs
  automatically on `create` (restore) and `destroy` (backup).
- **Secrets**: split config, non-secret in `group_vars/vars.yml`, secrets
  in an Ansible Vault-encrypted `group_vars/vault.yml`.
- **Extension point**: the Ansible `customization` role for
  project-specific packages and config.

## Setup

Prerequisites: Terraform >= 1.5, Ansible >= 2.15, an OVH Public Cloud
project, a domain name, a local SSH keypair.

1. **SSH key**: `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519`

2. **OVH credentials** (see ARCHITECTURE.md for why there are three):
   - OpenStack user: Manager → Public Cloud → project → Users & Roles →
     create a user, e.g. `Administrator` role.
   - API app credentials for the `ovh` provider:
     https://api.ovh.com/createToken/, rights on `/cloud/project/*` (plus
     `GET/POST/PUT/DELETE /domain/zone/*` if `manage_dns = true`). Scope
     tighter by replacing `*` with `<projectId>` / `<zone>` and
     `<projectId>/*` / `<zone>/*`.
   - S3 credentials for the Terraform state bucket: Manager → Public Cloud
     → project → Storage → Object Storage → Users tab.

   Export them (or use `~/.ovh.conf` for the `ovh` ones):
   ```bash
   export OS_USERNAME="..." OS_PASSWORD="..." OS_USER_DOMAIN_NAME="Default"
   export OVH_ENDPOINT="ovh-eu" OVH_APPLICATION_KEY="..." OVH_APPLICATION_SECRET="..." OVH_CONSUMER_KEY="..."
   export AWS_ACCESS_KEY_ID="..." AWS_SECRET_ACCESS_KEY="..."
   ```

3. **Terraform state bucket**: create one manually in Object Storage.

4. **Bootstrap** (once):
   ```bash
   cd terraform-bootstrap
   cp backend.tfvars.example backend.tfvars      # fill in your state bucket
   cp terraform.tfvars.example terraform.tfvars  # fill in ovh_project_id, ssh key path
   cd .. && make bootstrap
   ```

5. **Ephemeral config**:
   ```bash
   cd terraform-ephemeral
   cp backend.tfvars.example backend.tfvars      # same state bucket, different key
   cp terraform.tfvars.example terraform.tfvars  # adjust variables after copy
   cd ..
   ```

6. **Ansible config and secrets**:
   ```bash
   cp ansible/group_vars/vars.yml.example ansible/group_vars/vars.yml
   # fill in domain_name, letsencrypt_email, backup_paths, backup_excludes (plaintext, gitignored)
   cp ansible/group_vars/vault.yml.example ansible/group_vars/vault.yml
   # fill in the manual secrets, then encrypt:
   ansible-vault encrypt ansible/group_vars/vault.yml
   read -s -p "Vault password: " PASS && echo && printf '%s' "$PASS" > .vault_pass && chmod 600 .vault_pass && unset PASS
   ```

7. **Run it**:
   ```bash
   make create    # provision instance, restore last backup, ready to work
   make destroy   # backup current state, destroy instance
   ```

## Troubleshooting

- **"No suitable endpoint could be found in the service catalog"**:
  `compute_region`/`object_storage_region` (terraform-bootstrap) use
  different naming (`GRA11` vs `GRA`); check yours matches what your OVH
  project actually has.
- **`OverQuota` on `security_group`**: new OVH accounts get quota 0.
  Leave `create_security_group = false` (the default) or add a payment
  method to raise the quota.
- **"Neither a boot device, image ID, or image name..."**: `instance_image`
  must exactly match an active image name for your region.
- **Let's Encrypt fails on `make create`**: the public IPv4/IPv6 change
  every cycle; your DNS A/AAAA records must point at the new ones before
  Ansible reaches the nginx role. Use `manage_dns = true` or update them
  during the pause. If only IPv6 is broken, remove the AAAA (Let's Encrypt
  prefers it).
- **`make` keeps asking for the vault password**: create `.vault_pass`
  (step 6 above).
- **`OVHcloud API error (status code 403) ... not been granted` on DNS**:
  your API token lacks `/domain/zone/*` rights; recreate it (step 2) or
  set `manage_dns = false`.

## License

GNU Affero General Public License v3.0. See [LICENSE](LICENSE).

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at your
option) any later version. It is distributed WITHOUT ANY WARRANTY; without
even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE. See the license for details.
