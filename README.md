# OVH Cloud Dev Environment

A code-server (VS Code in the browser) instance on OVH Public Cloud that
you spin up to work and tear down when done, backing up your data to
Object Storage in between. See [ARCHITECTURE.md](ARCHITECTURE.md) for the
why behind each design choice.

## Setup

Prerequisites: Terraform >= 1.5, Ansible >= 2.15, an OVH Public Cloud
project, a domain name, a local SSH keypair.

1. **SSH key**: `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519`

2. **OVH credentials** (see ARCHITECTURE.md for why there are three):
   - OpenStack user: Manager → Public Cloud → project → Users & Roles →
     create a user, e.g. `Administrator` role.
   - API app credentials for the `ovh` provider:
     https://api.ovh.com/createToken/, rights on `/cloud/project/*`.
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
- **Let's Encrypt fails on `make create`**: the public IP changes every
  cycle; your DNS A record must point at the new one before Ansible
  reaches the nginx role. Use `manage_dns = true` or update it during the
  pause.
- **`make` keeps asking for the vault password**: create `.vault_pass`
  (step 6 above).

## License: GNU Affero General Public License v3.0

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. License Implications
