# Consumed automatically: `make` reads these into terraform-ephemeral's
# generated.tfvars (see the Makefile) and ansible/group_vars/vault.yml
# still needs the s3/backup_* ones copied in by hand (see README).

output "ovh_project_id" {
  description = "Echoed back so terraform-ephemeral doesn't need it typed twice."
  value       = var.ovh_project_id
}

output "compute_region" {
  description = "Echoed back so terraform-ephemeral stays in the same region."
  value       = var.compute_region
}

# Backups Object Storage, read by the Makefile's generate-vault-vars target.
output "backup_bucket_name" {
  description = "Swift container name for backups."
  value       = openstack_objectstorage_container_v1.backup_bucket.name
}

output "swift_region" {
  description = "Object Storage region for the backups container."
  value       = var.object_storage_region
}

output "swift_tenant_id" {
  description = "OpenStack project (tenant) id, used for Keystone v3 auth."
  value       = var.ovh_project_id
}

output "swift_username" {
  description = "Backup user's OpenStack username."
  value       = ovh_cloud_project_user.backup_user.username
}

output "swift_password" {
  description = "Backup user's OpenStack password."
  value       = ovh_cloud_project_user.backup_user.password
  sensitive   = true
}

output "keypair_name" {
  description = "Read by `make` into terraform-ephemeral's generated.tfvars."
  value       = openstack_compute_keypair_v2.dev_keypair.name
}