# AGENTS.md — ansible

Provisioning (`site.yml`), backup (`backup.yml`), restore (`restore.yml`).

## Rules

- Roles are additive: `security`, `nginx`, `code-server` are fixed. New
  customization goes into the `customization` role only, as one task file
  per tool, included from `tasks/main.yml` behind a `customization_<tool>`
  flag defaulting to `false` in `roles/customization/defaults/main.yml`.
- Install from pinned, checksummed artifacts or signed apt repos, never
  `curl | sh`. Version + sha256 live together in the role defaults.
- Anything a customization task writes under the dev user's home that a
  re-provision would recreate (toolchains, caches, downloaded runtimes)
  must be added to `backup_excludes` in `group_vars/vars.yml.example`.
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
- backup/restore pass the Swift credentials to rclone via
  `RCLONE_CONFIG_OVH_*` environment variables (`rclone_env` in each
  playbook), never via a config file: rclone would otherwise write
  `key = {{ swift_key }}` to disk in plaintext.
- backup/restore playbooks must stay idempotent and safe to re-run.
- Don't treat `inventory/generated.ini` as source of truth. Don't read
  `*.retry` files.
- Keep roles self-contained: no ordering assumptions beyond `site.yml`.
