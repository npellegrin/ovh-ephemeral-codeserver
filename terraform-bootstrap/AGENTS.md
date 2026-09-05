# AGENTS.md — terraform-bootstrap

Persistent resources only: Object Storage buckets, SSH keypair, network,
subnet, router. Applied once, rarely modified.

## Rules

- Never add a `terraform destroy`-triggering change without flagging it
  explicitly in the response — this state must not be casually destroyed.
- Do not introduce the `ovh` provider here. Only `openstack` is used in this
  stack. If DNS or account-level resources are needed, they belong in
  `terraform-ephemeral/`, not here.
- Do not touch `backend.tfvars` credentials logic — only bucket/endpoint/region
  values, never inline secrets.
- Do not read `.terraform/`, `*.tfstate*`, `.terraform.lock.hcl`.
- Keep this stack minimal: if a resource is not required to survive a daily
  destroy/recreate cycle, it does not belong here.
