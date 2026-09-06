# Least-privilege OVH Public Cloud user for backups, via the `ovh` provider
# (OVH's own project-user API), not raw OpenStack Identity — a project-scoped
# OpenStack token can't list/assign roles or create users there
# (identity:list_roles comes back 403 even for an Administrator-role user).

# Its generated username/password are used for Swift (OpenStack) auth by
# rclone in ansible/backup.yml and restore.yml.
resource "ovh_cloud_project_user" "backup_user" {
  service_name = var.ovh_project_id
  description  = "${local.resource_prefix}-backup-user"
  role_name    = "objectstore_operator"
}
