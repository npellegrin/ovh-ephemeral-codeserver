# AGENTS.md — ansible

Provisioning (`site.yml`), backup (`backup.yml`), restore (`restore.yml`).

## Rules

- Roles are additive: `security`, `nginx`, `code-server` are fixed. New
  customization (rustup, python, etc.) goes into the `customization` role
  only, as conditionally-included task files where reasonable.
- Don't weaken existing hardening (nftables, fail2ban, SSH config).
- nftables filters SSH/HTTP/HTTPS by `allowed_ssh_cidrs` /
  `allowed_http_cidrs` / `allowed_https_cidrs` and their `_v6` counterparts
  (group_vars/vars.yml), defaulting to `0.0.0.0/0` + `::/0`. This is the
  primary IP filter when terraform-ephemeral's `create_security_group` is
  `false` (the default). Keep the ICMPv6/NDP accept rules or IPv6 breaks.
- Two group_vars files, both gitignored, both loaded by every playbook via
  `vars_files`: `vars.yml` (plaintext, non-secret) and `vault.yml` (Vault-
  encrypted: `swift_user`, `swift_key`, `code_server_password`). Secrets go
  in `vault.yml`, never in plaintext YAML.
- backup/restore reach Object Storage through rclone's Swift backend (the
  container is created Swift-side by terraform-bootstrap; the S3 gateway
  doesn't see it). Auth uses the backup user's OpenStack username/password,
  not S3 keys.
- backup/restore write the rclone config (Swift credentials) inside a
  `block` whose `always` deletes it. Keep that structure; don't leave the
  credentials on disk after the run.
- backup/restore playbooks must stay idempotent and safe to re-run.
- Don't treat `inventory/generated.ini` as source of truth. Don't read
  `*.retry` files.
- Keep roles self-contained: no ordering assumptions beyond `site.yml`.
