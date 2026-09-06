# AGENTS.md — terraform-ephemeral

Compute instance (direct public IP on Ext-Net) and its security group.
Destroyed and recreated daily.

## Rules

- Instance size and disk size stay configurable via variables, never
  hardcoded.
- `create_security_group` (security.tf) defaults to `false`: new/unverified
  OVH accounts get a `security_group` quota of 0. Off, the instance uses
  the `default` group and nftables (Ansible) is the only IP filter for
  HTTP/HTTPS; SSH stays open in nftables regardless. Don't assume the
  dedicated security group is active.
- Any resource here must be safe to destroy without data loss. State-
  holding resources belong in `terraform-bootstrap/`.
- `ovh` provider is allowed here only for DNS records. Gated behind
  `manage_dns` (default `false`); when off, `make create` pauses for a
  manual DNS update before Ansible. `dns_subdomain` + `dns_zone` must
  resolve to ansible's `domain_name`.
- Don't read `.terraform/`, `*.tfstate*`, `.terraform.lock.hcl`.
- Output values consumed by Ansible (`public_ipv4`, etc.) must stay stable
  in name and type: inventory generation depends on them.
- `ovh_project_id`, `compute_region`, `keypair_name` come from
  terraform-bootstrap's outputs via the Makefile's `generate-ephemeral-vars`
  target (generated.tfvars), not terraform.tfvars. Keep the output names
  matching if you rename these.
- The instance attaches directly to `Ext-Net` (no private network/router)
  to avoid a billed, always-on OVH "Gateway". Don't reintroduce a private
  subnet/router without discussing the cost tradeoff.
