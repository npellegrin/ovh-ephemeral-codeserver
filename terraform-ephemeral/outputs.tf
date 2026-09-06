output "instance_id" {
  value = openstack_compute_instance_v2.dev_instance.id
}

output "public_ip" {
  value = openstack_compute_instance_v2.dev_instance.access_ip_v4
}

output "volume_id" {
  value = openstack_blockstorage_volume_v3.dev_volume.id
}

# Consumed by the Makefile to decide whether `make create` pauses for a
# manual DNS update before running Ansible.
output "dns_managed" {
  value = var.manage_dns
}
