# Architecture

Design choices and rationale. See [README.md](README.md) for what this is
and how to run it.

## Why ephemeral, not shelved

OVH bills a shelved instance for its flavor (reduced rate) plus full disk
storage. For a few-hours-a-day pattern, destroying the instance and disk
daily and backing up to Object Storage (billed per GB/month) is cheaper
than shelving below ~50% daily uptime.

## Bootstrap vs ephemeral split

Two separate Terraform states:

- `terraform-bootstrap`: what must survive a destroy (backups bucket, state
  bucket, keypair). Applied once.
- `terraform-ephemeral`: instance, security group, public IPv4/IPv6.
  Destroyed and recreated every cycle.

A `terraform destroy` mistake in daily use can't wipe backups or remote
state.

## No network gateway

The instance attaches directly to OVH's `Ext-Net` (`image_id` +
`network { uuid = ... }` on `openstack_compute_instance_v2`, no floating
IP or router). A router with an external gateway provisions a billed OVH
"Gateway" that would run continuously in the always-on bootstrap stack.

## OVH credentials: three separate sets

- **OpenStack user** (username/password): the `openstack` provider, for
  compute/network/storage. Created in Manager under Users & Roles.
- **OVH API app credentials** (application key/secret/consumer key): the
  `ovh` provider, only to create the least-privilege backups user via
  OVH's project-user API.
- **S3 credentials for the state bucket**: needed before Terraform can run,
  so they can't be created by Terraform. Unrelated to the backups user.

## Least-privilege backup user

A project-scoped OpenStack token can't manage users/roles
(`identity:list_roles` returns 403 even for an Administrator-role user), so
`terraform-bootstrap/iam.tf` uses `ovh_cloud_project_user` (role
`objectstore_operator`). rclone (Ansible) authenticates to Swift with that
user's generated username/password.

The backups container is created Swift-side
(`openstack_objectstorage_container_v1`). OVH's S3 gateway doesn't expose
Swift-created containers, so rclone uses `type = swift`. A leaked
credential from the instance can only touch Object Storage, but Object
Storage holds full tarballs of the dev user's home directory, so treat it
as sensitive. `backup.yml` / `restore.yml` write the rclone config
(credentials) only for the run and delete it in an `always` block;
`*/.config/rclone` is also in `backup_excludes`.

## Security group vs nftables

New/unverified OVH accounts get a `security_group` quota of 0 (to stop
bypassing OVH's default outbound block on ports 25/465/587). So
`create_security_group` (terraform-ephemeral) defaults to `false`: the
instance uses the project's `default` group, and nftables (Ansible)
filters SSH/HTTP/HTTPS via `allowed_ssh_cidrs` / `allowed_http_cidrs` /
`allowed_https_cidrs` and their `_v6` counterparts in
`group_vars/vars.yml`.

IPv4 defaults to `0.0.0.0/0`, IPv6 to `::/0`. SSH isn't restricted by
default: narrowing it risks a self-lockout if your address changes. Once
quota allows it, `create_security_group = true` adds the same filtering at
the OpenStack level.

Since HTTPS is open by default, the code-server login has app-layer
protection too: nginx `limit_req` on `/login` (zone in
`conf.d/code-server-limits.conf`) and a fail2ban jail reading a dedicated
`/var/log/nginx/code-server-login.log`. fail2ban bans via `nftables-*`
actions (`banaction` in `jail.local`) since the box has no iptables, and
`/etc/nftables.conf` replaces only its own table (not `flush ruleset`) so
reloading it keeps fail2ban's bans.

## Let's Encrypt needs port 80 open

Certbot uses the ACME HTTP-01 challenge (`certonly --webroot`). Let's
Encrypt hits port 80 from arbitrary addresses on every renewal, not just
once. A deploy hook reloads nginx after renewal. Narrowing
`allowed_http_cidrs` / `allowed_http_cidrs_v6` breaks renewal unless you
switch to DNS-01. With an AAAA record published, Let's Encrypt prefers
IPv6, so a broken IPv6 path also breaks renewal.

## Auto-generated files

`make` regenerates these from `terraform-bootstrap`'s outputs on every
run. None are committed:

- `terraform-ephemeral/generated.tfvars`: `ovh_project_id`,
  `compute_region`, `keypair_name`, passed via `-var-file` so they can't
  drift from bootstrap.
- `ansible/group_vars/vars.yml` (plaintext): `backup_bucket`,
  `swift_region`, `swift_tenant_id`.
- `ansible/group_vars/vault.yml` (encrypted): `swift_user`, `swift_key`,
  and a freshly generated `code_server_password`. The password rotates
  every run since the instance is rebuilt anyway.

`.vault_pass` (gitignored) holds the vault password so calls don't prompt.

## Upgrading code-server

Installs from a pinned, checksummed `.deb` release asset (no `curl | sh`),
see `ansible/roles/code-server/tasks/main.yml`. To bump:

1. Pick the target release tag from
   [github.com/coder/code-server/releases](https://github.com/coder/code-server/releases).
2. Get the sha256 of its `code-server_<version>_amd64.deb` asset:
   `curl -s https://api.github.com/repos/coder/code-server/releases/tags/v<version> | jq -r '.assets[] | select(.name == "code-server_<version>_amd64.deb") | .digest'`
   (strip the `sha256:` prefix), or `sha256sum` the downloaded `.deb`.
3. Update `code_server_version` and `code_server_deb_sha256` in
   `ansible/roles/code-server/defaults/main.yml`.
4. Re-run `make create`. `get_url` fails closed on a checksum mismatch.

## Security notes

- Root SSH login disabled, key-only auth
- fail2ban on sshd and on the code-server login, plus nginx `limit_req`
  on `/login`
- Automatic security updates enabled
- TLS-only for code-server (nginx + Let's Encrypt)
- Secrets via Ansible Vault, never committed in plaintext
- Swift credentials on the instance are removed after each backup/restore
- `backend.tfvars` contains no secrets and is safe to commit
- `terraform-bootstrap`'s state holds the backups bucket's S3 secret key in
  plaintext (Terraform state always does). Treat state bucket access as
  sensitive, same as `group_vars/vault.yml`
