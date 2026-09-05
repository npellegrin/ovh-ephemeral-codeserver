# Providers for Terraform ephemeral deployment.

# openstack: auth via OS_USERNAME/OS_PASSWORD/OS_USER_DOMAIN_NAME env vars.
provider "openstack" {
  auth_url    = "https://auth.cloud.ovh.net/v3"
  region      = var.compute_region
  tenant_id   = var.ovh_project_id
  domain_name = "default"
}
