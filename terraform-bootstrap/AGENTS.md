# AGENTS.md — terraform-bootstrap

Persistent resources only: Object Storage buckets, SSH keypair. Applied
once, rarely modified.

No network/subnet/router here on purpose: a router with an external
gateway provisions a billed, always-on OVH "Gateway". terraform-ephemeral
attaches instances directly to Ext-Net instead.

## Rules

- Never add a `terraform destroy`-triggering change without flagging it
  explicitly in the response. This state must not be casually destroyed.
- `openstack` handles compute/network/storage. `ovh` is allowed here only
  for Public Cloud project user/IAM (`ovh_cloud_project_user`,
  `ovh_cloud_project_user_s3_credential`): a project-scoped OpenStack token
  can't manage users/roles, and these are persistent. Account-level `ovh`
  resources (DNS, etc.) belong in `terraform-ephemeral/`.
- Don't touch `backend.tfvars` credentials logic, only bucket/endpoint/
  region values. Never inline secrets.
- Don't read `.terraform/`, `*.tfstate*`, `.terraform.lock.hcl`.
- Keep this stack minimal: if a resource doesn't need to survive the daily
  destroy/recreate cycle, it doesn't belong here.
