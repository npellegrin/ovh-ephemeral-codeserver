# AGENTS.md — terraform-bootstrap

Persistent resources only: Object Storage buckets, SSH keypair. Applied
once, rarely modified.

No network/subnet/router here on purpose: a router with an external gateway
provisions a billed OVH "Gateway" that would run continuously if it lived in
this always-on stack. terraform-ephemeral attaches instances directly to
Ext-Net instead, see terraform-ephemeral/compute.tf.

## Rules

- Never add a `terraform destroy`-triggering change without flagging it
  explicitly in the response — this state must not be casually destroyed.
- `openstack` handles compute/network/storage. `ovh` is allowed here only for
  Public Cloud project user/IAM management (`ovh_cloud_project_user`,
  `ovh_cloud_project_user_s3_credential`). A project-scoped OpenStack token
  can't manage users/roles itself (no identity:list_roles rights), and these
  are persistent, bootstrap-lifecycle resources. DNS or other account-level
  `ovh` resources still belong in `terraform-ephemeral/`, not here.
- Do not touch `backend.tfvars` credentials logic — only bucket/endpoint/region values, never inline secrets.
- Do not read `.terraform/`, `*.tfstate*`, `.terraform.lock.hcl`.
- Keep this stack minimal: if a resource is not required to survive a daily
  destroy/recreate cycle, it does not belong here.
