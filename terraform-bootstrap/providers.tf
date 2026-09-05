# Auth via OS_USERNAME/OS_PASSWORD/OS_USER_DOMAIN_NAME env vars (see README).

provider "openstack" {
  auth_url    = "https://auth.cloud.ovh.net/v3"
  region      = var.region
  tenant_id   = var.ovh_project_id
  domain_name = "default"
}
