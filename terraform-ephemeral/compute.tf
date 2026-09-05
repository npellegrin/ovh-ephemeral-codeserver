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
  # "default" is the project's built-in group when create_security_group is off. Not a placeholder, that's its literal name.
  security_groups = var.create_security_group ? [openstack_networking_secgroup_v2.dev_secgroup[0].name] : ["default"]

  block_device {
    uuid                  = data.openstack_images_image_v2.base_image.id
    source_type           = "image"
    destination_type      = "local"
    boot_index            = 0
    delete_on_termination = true
  }

  network {
    name = "Ext-Net"
  }
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
