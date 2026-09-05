# Network/subnet/router for the dev environment.

resource "openstack_networking_network_v2" "dev_network" {
  region         = var.compute_region
  name           = "${local.resource_prefix}-network"
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "dev_subnet" {
  region          = var.compute_region
  name            = "${local.resource_prefix}-subnet"
  network_id      = openstack_networking_network_v2.dev_network.id
  cidr            = "192.168.100.0/24"
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "1.1.1.1"]
}

resource "openstack_networking_router_v2" "dev_router" {
  region              = var.compute_region
  name                = "${local.resource_prefix}-router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.external.id
}

resource "openstack_networking_router_interface_v2" "dev_router_interface" {
  region    = var.compute_region
  router_id = openstack_networking_router_v2.dev_router.id
  subnet_id = openstack_networking_subnet_v2.dev_subnet.id
}

data "openstack_networking_network_v2" "external" {
  region   = var.compute_region
  name     = "Ext-Net"
  external = true
}
