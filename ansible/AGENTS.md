# AGENTS.md — ansible

Provisioning (`site.yml`), backup (`backup.yml`), restore (`restore.yml`).

## Rules

- Roles are additive: `security`, `nginx`, `code-server` are fixed; new
  customization (rustup, python, etc.) goes into the `customization` role
  only, as separate tasks files included conditionally if reasonable.
- Do not weaken existing hardening (nftables rules, fail2ban, SSH config)
  when adding new roles or tasks.
- nftables filters SSH/HTTP/HTTPS by `allowed_ssh_cidrs`/`allowed_http_cidrs`/
  `allowed_https_cidrs` (group_vars/vault.yml), all defaulting to
  `0.0.0.0/0`. This is the primary IP filter when terraform-ephemeral's
  `create_security_group` is `false` (the default, see its AGENTS.md).
- Secrets go in `group_vars/vault.yml`, encrypted with Ansible Vault. Never
  write secrets in plaintext YAML.
- Backup/restore playbooks must remain idempotent and safe to re-run.
- Do not read `inventory/generated.ini` as a source of truth for code
  changes — it's a generated artifact, not meant to be edited or reviewed.
- Do not read any `*.retry` files.
- Keep roles self-contained: a role should not assume ordering beyond what's
  declared in `site.yml`.
