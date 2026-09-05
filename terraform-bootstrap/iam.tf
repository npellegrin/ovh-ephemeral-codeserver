# Least-privilege OpenStack user for backups

# Needed to read the domain of the identity Terraform is authenticated as,
# so the new user is created in the same domain.
data "openstack_identity_auth_scope_v3" "current" {
  name = "bootstrap-provider-scope"
}

resource "random_password" "backup_user" {
  length  = 32
  special = false
}

resource "openstack_identity_user_v3" "backup_user" {
  name      = "${local.resource_prefix}-backup-user"
  password  = random_password.backup_user.result
  domain_id = data.openstack_identity_auth_scope_v3.current.user_domain_id
  enabled   = true
}

# Looked up by name, not created: OVH's Object Storage policy only
# recognizes its own predefined role names. Verify this string against
# Users & Roles in the Manager before the first apply — a mismatch fails
# the apply cleanly here rather than silently granting a different role.
data "openstack_identity_role_v3" "backup_role" {
  name = "ObjectStore Operator"
}

resource "openstack_identity_role_assignment_v3" "backup_user_role" {
  user_id    = openstack_identity_user_v3.backup_user.id
  project_id = var.ovh_project_id
  role_id    = data.openstack_identity_role_v3.backup_role.id
}

# S3-compatible credentials for the backups bucket, scoped to backup_user
# above (not the admin identity). Copy into ansible/group_vars/vault.yml.
resource "openstack_identity_ec2_credential_v3" "backup_s3" {
  region     = var.region
  user_id    = openstack_identity_user_v3.backup_user.id
  project_id = var.ovh_project_id

  depends_on = [openstack_identity_role_assignment_v3.backup_user_role]
}
