# Consumed by terraform-ephemeral/terraform.tfvars and ansible/group_vars/vault.yml.

output "s3_bucket_name" {
  description = "Backups bucket name. Copy into ansible/group_vars/vault.yml as s3_bucket_name."
  value       = openstack_objectstorage_container_v1.backup_bucket.name
}

output "backup_s3_endpoint" {
  description = "OVH Object Storage S3 endpoint for the backups bucket's region."
  value       = "https://s3.${lower(var.region)}.io.cloud.ovh.net"
}

output "backup_s3_access_key" {
  description = "S3 access key for the backups bucket. Copy into ansible/group_vars/vault.yml as s3_access_key."
  value       = openstack_identity_ec2_credential_v3.backup_s3.access
}

output "backup_s3_secret_key" {
  description = "S3 secret key for the backups bucket. Copy into ansible/group_vars/vault.yml as s3_secret_key."
  value       = openstack_identity_ec2_credential_v3.backup_s3.secret
  sensitive   = true
}

output "keypair_name" {
  description = "Copy into terraform-ephemeral/terraform.tfvars as keypair_name."
  value       = openstack_compute_keypair_v2.dev_keypair.name
}

output "network_id" {
  description = "Copy into terraform-ephemeral/terraform.tfvars as network_id."
  value       = openstack_networking_network_v2.dev_network.id
}

output "subnet_id" {
  description = "Copy into terraform-ephemeral/terraform.tfvars as subnet_id."
  value       = openstack_networking_subnet_v2.dev_subnet.id
}