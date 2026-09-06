# Architecture

Design choices and rationale. See [README.md](README.md) for what this is
and how to run it.

## Why ephemeral, not shelved

OVH still bills a shelved instance for its flavor (reduced rate) and full
disk storage. Shelving only cuts the compute-hour cost, not storage. For a
few-hours-a-day usage pattern, destroying the instance and disk daily and
backing up to Object Storage (billed per GB/month, no attachment lifecycle)
is cheaper than shelving for any usage under ~50% daily uptime.

## Bootstrap vs ephemeral split

Two separate Terraform states. `terraform-bootstrap` holds what must
survive a destroy (backups bucket, state bucket, keypair) and is applied
once. `terraform-ephemeral` holds only the instance, its security group,
and its public IPv4/IPv6, destroyed and recreated every cycle. A `terraform
destroy` mistake in daily use can't wipe your backups or remote state.

## No network gateway

The instance attaches directly to OVH's `Ext-Net` for its public IPv4 and
IPv6 (`image_id` + `network { uuid = ... }` on
`openstack_compute_instance_v2`, no `block_device`/floating IP/router). A router with an external gateway
provisions a billed OVH "Gateway" resource, which would run continuously
if it lived in the always-on bootstrap stack. `block_device` was tried
first and failed apply-time with "Neither a boot device, image ID, or
image name were able to be determined" for reasons that didn't trace back
to config (image and flavor were both valid); `image_id` sidesteps
whatever provider-internal issue that was, and is simpler anyway since the
extra data volume attaches separately post-boot.

## OVH credentials: three separate sets

- **OpenStack user** (username/password): Terraform's `openstack` provider
  uses this for compute/network/storage. Created in Manager under Users &
  Roles.
- **OVH API app credentials** (application key/secret/consumer key): the
  `ovh` provider uses this only to create the least-privilege backups user
  (see below) via OVH's own project-user API, not raw OpenStack Identity.
- **S3 credentials for the Terraform state bucket**: Terraform needs these
  *before* it can run at all (to store its own state), so they can't be
  created by Terraform itself. Separate from the backups bucket's S3
  credentials, which `terraform-bootstrap` generates.

## Least-privilege backup user

A project-scoped OpenStack token can't manage users/roles itself
(`identity:list_roles` comes back 403 even for an Administrator-role
user), so `terraform-bootstrap/iam.tf` uses the `ovh` provider's
`ovh_cloud_project_user` (role `objectstore_operator`) and
`ovh_cloud_project_user_s3_credential` instead of raw OpenStack Identity
resources. If the S3 credential ever leaks from the ephemeral instance, it
can only touch Object Storage, not compute/network/the state bucket.

## Security group vs nftables

New/unverified OVH accounts get a `security_group` quota of 0 (likely to
stop them bypassing OVH's default outbound block on ports 25/465/587, an
anti-spam-relay measure). `create_security_group` (terraform-ephemeral)
defaults to `false`: the instance uses the project's built-in `default`
group, and nftables (Ansible) does the filtering for SSH/HTTP/HTTPS
instead, via `allowed_ssh_cidrs`/`allowed_http_cidrs`/`allowed_https_cidrs`
and their `_v6` counterparts in `group_vars/vars.yml`. IPv4 defaults to
`0.0.0.0/0`, IPv6 to `::/0`; narrowing SSH's risks a self-lockout if your
address changes, so it isn't restricted by default even though the
variable exists. Once your account's quota allows it,
`create_security_group = true` adds the same filtering at the OpenStack
level too.

## Let's Encrypt needs port 80 open

Certbot uses the ACME HTTP-01 challenge (`certonly --webroot`), which Let's
Encrypt's servers hit on port 80 from arbitrary addresses, both for the
initial certificate and every renewal (not just once). A deploy hook
reloads nginx after each renewal. Narrowing `allowed_http_cidrs` /
`allowed_http_cidrs_v6` from their defaults breaks renewal unless you
switch to a DNS-01 challenge instead. With an AAAA record published, Let's
Encrypt prefers IPv6, so a half-broken IPv6 path breaks renewal too.

## Auto-generated files

`make` regenerates two files from `terraform-bootstrap`'s outputs on every
run, neither committed:

- `terraform-ephemeral/generated.tfvars`: `ovh_project_id`, `compute_region`,
  `keypair_name`, passed via `-var-file` so they can't drift from what
  bootstrap actually created.
- `ansible/group_vars/vault.yml`: the `generate-vault-vars` Makefile target
  decrypts it (or reads it as plaintext, before the first encryption),
  injects `s3_bucket`/`s3_endpoint`/`s3_access_key`/`s3_secret_key` from
  bootstrap's outputs and a freshly generated `code_server_password` (every
  run, since the instance is rebuilt every cycle anyway), then re-encrypts.
  `.vault_pass` (gitignored) holds the vault password so this and every
  `ansible-playbook` call don't prompt repeatedly.

## Upgrading code-server

code-server installs from a pinned, checksummed `.deb` release asset (no
`curl | sh`), see `ansible/roles/code-server/tasks/main.yml`. To bump the
version:

1. Pick the target release tag from
   [github.com/coder/code-server/releases](https://github.com/coder/code-server/releases)
   (e.g. `v4.135.0`).
2. Get the sha256 digest of its `code-server_<version>_amd64.deb` asset:
   `curl -s https://api.github.com/repos/coder/code-server/releases/tags/v<version>
   | jq -r '.assets[] | select(.name == "code-server_<version>_amd64.deb") | .digest'`
   (strip the `sha256:` prefix), or download the `.deb` and run `sha256sum`.
3. Update `code_server_version` and `code_server_deb_sha256` in
   `ansible/roles/code-server/defaults/main.yml`.
4. Re-run `make create`. The `get_url` task fails closed on a checksum
   mismatch instead of installing something unverified.

## Security notes

- Root SSH login disabled, key-only auth
- fail2ban on sshd
- Automatic security updates enabled
- TLS-only for code-server (nginx + Let's Encrypt)
- Secrets managed via Ansible Vault, never committed in plaintext
- `backend.tfvars` contains no secrets and is safe to commit; only
  credentials (env vars) are excluded from version control
- `terraform-bootstrap`'s state holds the backups bucket's S3 secret key in
  plaintext (Terraform state always does, for any resource-managed secret).
  Treat access to the Terraform state bucket itself as sensitive, same as
  `group_vars/vault.yml`
