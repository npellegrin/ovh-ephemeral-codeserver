# Least-privilege OVH Public Cloud user for backups, via the `ovh` provider
# (OVH's own project-user API), not raw OpenStack Identity — a project-scoped
# OpenStack token can't list/assign roles or create users there
# (identity:list_roles comes back 403 even for an Administrator-role user).

resource "ovh_cloud_project_user" "backup_user" {
  service_name = var.ovh_project_id
  description  = "${local.resource_prefix}-backup-user"
  role_name    = "objectstore_operator"
}

# S3-compatible credentials for the backups bucket, scoped to backup_user
# above (not the admin identity). Copy into ansible/group_vars/vault.yml.
resource "ovh_cloud_project_user_s3_credential" "backup_s3" {
  service_name = var.ovh_project_id
  user_id      = ovh_cloud_project_user.backup_user.id
}
