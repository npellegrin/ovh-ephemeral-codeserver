# Providers for Terraform bootstrap deployment.

# openstack: auth via OS_USERNAME/OS_PASSWORD/OS_USER_DOMAIN_NAME env vars.
provider "openstack" {
  auth_url    = "https://auth.cloud.ovh.net/v3"
  region      = var.object_storage_region
  tenant_id   = var.ovh_project_id
  domain_name = "default"
}

# ovh: auth via OVH_ENDPOINT/OVH_APPLICATION_KEY/OVH_APPLICATION_SECRET/
# OVH_CONSUMER_KEY env vars, or ~/.ovh.conf. Both documented in the README.
# No resource uses it any more (the backup user moved to terraform-ephemeral);
# kept so the next apply can destroy the one left in this stack's state.
# Droppable, with the ovh entry in versions.tf, once that apply has run.
provider "ovh" {}
