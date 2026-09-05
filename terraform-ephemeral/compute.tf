# Instance and its attached disk. The instance attaches directly to Ext-Net
# (no private subnet/router/floating IP): that combo provisions a billed
# OVH "Gateway" resource that would run continuously, since it'd live in
# terraform-bootstrap. Direct Ext-Net attachment gets a public IP without it.

resource "openstack_blockstorage_volume_v3" "dev_volume" {
  region      = var.compute_region
  name        = "${local.resource_prefix}-volume"
  size        = var.volume_size_gb
  volume_type = "high-speed" # SSD/NVMe depending on regional availability
}

resource "openstack_compute_instance_v2" "dev_instance" {
  region      = var.compute_region
  name        = "${local.resource_prefix}-instance"
  flavor_name = var.instance_flavor
  key_pair    = var.keypair_name
  image_id    = data.openstack_images_image_v2.base_image.id
  # "default" is the project's built-in group when create_security_group is off. Not a placeholder, that's its literal name.
  security_groups = var.create_security_group ? [openstack_networking_secgroup_v2.dev_secgroup[0].name] : ["default"]

  network {
    uuid = data.openstack_networking_network_v2.external.id
  }
}

data "openstack_networking_network_v2" "external" {
  region   = var.compute_region
  name     = "Ext-Net"
  external = true
}

resource "openstack_compute_volume_attach_v2" "dev_volume_attach" {
  region      = var.compute_region
  instance_id = openstack_compute_instance_v2.dev_instance.id
  volume_id   = openstack_blockstorage_volume_v3.dev_volume.id
}

data "openstack_images_image_v2" "base_image" {
  region      = var.compute_region
  name        = var.instance_image
  most_recent = true
}
