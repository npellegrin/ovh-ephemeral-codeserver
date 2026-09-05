# SSH keypair used to access instances.

resource "openstack_compute_keypair_v2" "dev_keypair" {
  region     = var.compute_region
  name       = "${local.resource_prefix}-keypair"
  public_key = file(var.ssh_public_key_path)
}
