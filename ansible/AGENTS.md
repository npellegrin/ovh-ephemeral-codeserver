# AGENTS.md — ansible

Provisioning (`site.yml`), backup (`backup.yml`), restore (`restore.yml`).

## Rules

- Roles are additive: `security`, `nginx`, `code-server` are fixed; new
  customization (rustup, python, etc.) goes into the `customization` role
  only, as separate tasks files included conditionally if reasonable.
- Do not weaken existing hardening (nftables rules, fail2ban, SSH config)
  when adding new roles or tasks.
- nftables filters SSH/HTTP/HTTPS by `allowed_ssh_cidrs`/`allowed_http_cidrs`/
  `allowed_https_cidrs` and their `_v6` counterparts (group_vars/vars.yml),
  defaulting to `0.0.0.0/0` + `::/0`. This is the primary IP filter when
  terraform-ephemeral's `create_security_group` is `false` (the default, see
  its AGENTS.md). Keep the ICMPv6/NDP accept rules: without them IPv6 breaks.
- Two group_vars files, both gitignored, both loaded by every playbook via
  `vars_files`: `vars.yml` (plaintext, non-secret config) and `vault.yml`
  (Ansible Vault-encrypted, secrets only: `s3_access_key`, `s3_secret_key`,
  `code_server_password`). Secrets go in `vault.yml`. Never write secrets in
  plaintext YAML. New non-secret vars go in `vars.yml`.
- Backup/restore playbooks must remain idempotent and safe to re-run.
- Do not read `inventory/generated.ini` as a source of truth for code
  changes — it's a generated artifact, not meant to be edited or reviewed.
- Do not read any `*.retry` files.
- Keep roles self-contained: a role should not assume ordering beyond what's
  declared in `site.yml`.
