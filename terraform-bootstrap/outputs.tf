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

output "s3_bucket_name" {
  description = "Backups bucket name. Copy into ansible/group_vars/vault.yml as s3_bucket_name."
  value       = openstack_objectstorage_container_v1.backup_bucket.name
}

output "backup_s3_endpoint" {
  description = "OVH Object Storage S3 endpoint for the backups bucket's region."
  value       = "https://s3.${lower(var.object_storage_region)}.io.cloud.ovh.net"
}

output "backup_s3_access_key" {
  description = "S3 access key for the backups bucket. Copy into ansible/group_vars/vault.yml as s3_access_key."
  value       = ovh_cloud_project_user_s3_credential.backup_s3.access_key_id
}

output "backup_s3_secret_key" {
  description = "S3 secret key for the backups bucket. Copy into ansible/group_vars/vault.yml as s3_secret_key."
  value       = ovh_cloud_project_user_s3_credential.backup_s3.secret_access_key
  sensitive   = true
}

output "keypair_name" {
  description = "Read by `make` into terraform-ephemeral's generated.tfvars."
  value       = openstack_compute_keypair_v2.dev_keypair.name
}