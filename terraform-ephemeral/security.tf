# Security group: SSH/HTTPS/HTTP ingress, all egress. nftables (Ansible) is
# the second layer, see terraform-ephemeral/AGENTS.md.

resource "openstack_networking_secgroup_v2" "dev_secgroup" {
  region      = var.compute_region
  name        = "${local.resource_prefix}-secgroup"
  description = "Security group for the development environment - restricted access"
}

resource "openstack_networking_secgroup_rule_v2" "ssh_ingress" {
  for_each = toset(var.allowed_ssh_cidrs)

  region            = var.compute_region
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = each.value
  security_group_id = openstack_networking_secgroup_v2.dev_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "https_ingress" {
  for_each = toset(var.allowed_https_cidrs)

  region            = var.compute_region
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = each.value
  security_group_id = openstack_networking_secgroup_v2.dev_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "http_ingress" {
  for_each = toset(var.allowed_http_cidrs)

  region            = var.compute_region
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = each.value
  security_group_id = openstack_networking_secgroup_v2.dev_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "egress_all" {
  region            = var.compute_region
  direction         = "egress"
  ethertype         = "IPv4"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.dev_secgroup.id
}
