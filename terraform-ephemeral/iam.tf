# Least-privilege OVH Public Cloud user for backups, via the `ovh` provider
# (OVH's own project-user API), not raw OpenStack Identity: a project-scoped
# OpenStack token can't list/assign roles or create users there
# (identity:list_roles comes back 403 even for an Administrator-role user).

# It lives in this stack rather than terraform-bootstrap so the credential is
# recreated on every create/destroy cycle. `objectstore_operator` is scoped to
# the whole project (every container, state buckets included), so capping its
# lifetime to one cycle is what limits the damage from a leaked copy.
# The Makefile's generate-swift-vars target reads the outputs below into
# ansible/group_vars/vault.yml after apply; rclone authenticates to Swift with
# them in backup.yml / restore.yml.
resource "ovh_cloud_project_user" "backup_user" {
  service_name = var.ovh_project_id
  description  = "${local.resource_prefix}-backup-user"
  role_name    = "objectstore_operator"
}
