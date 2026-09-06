# Optional A/AAAA records in an OVH DNS zone, pointing at the instance's
# public IPv4 and IPv6. Toggled by manage_dns; the zone is refreshed
# automatically on apply. The AAAA is skipped when the instance has no IPv6.

locals {
  instance_ipv4 = openstack_compute_instance_v2.dev_instance.access_ip_v4
  instance_ipv6 = openstack_compute_instance_v2.dev_instance.network[0].fixed_ip_v6
}

resource "ovh_domain_zone_record" "dev_a" {
  count = var.manage_dns ? 1 : 0

  zone      = var.dns_zone
  subdomain = var.dns_subdomain
  fieldtype = "A"
  ttl       = var.dns_ttl
  target    = local.instance_ipv4
}

resource "ovh_domain_zone_record" "dev_aaaa" {
  count = var.manage_dns && local.instance_ipv6 != "" ? 1 : 0

  zone      = var.dns_zone
  subdomain = var.dns_subdomain
  fieldtype = "AAAA"
  ttl       = var.dns_ttl
  target    = local.instance_ipv6
}
