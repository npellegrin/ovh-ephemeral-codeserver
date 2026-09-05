# Terraform and provider version constraints.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 3.4"
    }
    ovh = {
      source  = "ovh/ovh"
      version = "~> 2.0"
    }
  }
}
