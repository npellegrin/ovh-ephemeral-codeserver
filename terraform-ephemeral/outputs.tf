output "instance_id" {
  value = openstack_compute_instance_v2.dev_instance.id
}

output "public_ipv4" {
  value = local.instance_ipv4
}

output "public_ipv6" {
  value = local.instance_ipv6
}

output "volume_id" {
  value = openstack_blockstorage_volume_v3.dev_volume.id
}

# Consumed by the Makefile to decide whether `make create` pauses for a
# manual DNS update before running Ansible.
output "dns_managed" {
  value = var.manage_dns
}

# Backup user credentials, read by the Makefile's generate-swift-vars target
# into ansible/group_vars/vault.yml. Only available after apply, so that target
# can't be a prerequisite of `make create` the way generate-vault-vars is.
output "swift_username" {
  value = ovh_cloud_project_user.backup_user.username
}

output "swift_password" {
  value     = ovh_cloud_project_user.backup_user.password
  sensitive = true
}
