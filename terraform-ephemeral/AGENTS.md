# AGENTS.md — terraform-ephemeral

Compute instance (with a direct public IP on Ext-Net) and its security
group. Destroyed and recreated daily.

## Rules

- Instance size and disk size must remain configurable via variables, never
  hardcoded.
- `create_security_group` (security.tf) defaults to `false`: new/unverified
  OVH accounts get a `security_group` quota of 0. Off, the instance uses
  the project's built-in `default` group and nftables (Ansible) is the only
  IP filter for HTTP/HTTPS; SSH stays open in nftables regardless (see
  ansible/AGENTS.md). Don't assume the dedicated security group is active.
- Any resource added here must be safe to destroy without data loss — if it
  holds state, it belongs in `terraform-bootstrap/` instead.
- `ovh` provider is allowed here only for DNS record automation, nothing else.
- Do not read `.terraform/`, `*.tfstate*`, `.terraform.lock.hcl`.
- Output values consumed by Ansible (`public_ip`, etc.) must stay stable in
  name and type — Ansible inventory generation depends on them.
- `ovh_project_id`, `compute_region`, `keypair_name` come from
  terraform-bootstrap's outputs via the Makefile's `generate-ephemeral-vars`
  target (generated.tfvars), not from terraform.tfvars. Keep matching
  output names in terraform-bootstrap if you rename any of these variables.
- The instance attaches directly to `Ext-Net` (no private network/router):
  that avoids provisioning a billed, always-on OVH "Gateway". Don't
  reintroduce a private subnet/router without discussing the cost tradeoff.
