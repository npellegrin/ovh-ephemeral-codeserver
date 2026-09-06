# Optional A record in an OVH DNS zone, pointing at the instance's public IP.
# Toggled by manage_dns; the zone is refreshed automatically on apply.

resource "ovh_domain_zone_record" "dev" {
  count = var.manage_dns ? 1 : 0

  zone      = var.dns_zone
  subdomain = var.dns_subdomain
  fieldtype = "A"
  ttl       = var.dns_ttl
  target    = openstack_compute_instance_v2.dev_instance.access_ip_v4
}
