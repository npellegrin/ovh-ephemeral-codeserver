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
- `ovh` provider is used for two things: DNS records (gated behind
  `manage_dns`, default `false`; when off, `make create` pauses for a
  manual DNS update before Ansible; `dns_subdomain` + `dns_zone` must
  resolve to ansible's `domain_name`) and the backup user
  (`ovh_cloud_project_user` in `iam.tf`, unconditional). The backup user
  lives here rather than in terraform-bootstrap so its credential rotates
  every create/destroy cycle instead of living forever: a project-scoped
  OpenStack token can't manage users/roles, so it still goes through
  OVH's project-user API, not raw OpenStack Identity.
- `iam.tf`'s outputs (`swift_username`, `swift_password`) are only valid
  after `terraform apply`. The Makefile's `generate-swift-vars` target
  reads them and can't be a prerequisite of `create` the way
  `generate-vault-vars` is; it must run after `terraform apply`.
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
