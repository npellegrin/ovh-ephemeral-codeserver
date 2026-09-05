# Remote state in OVH Object Storage (S3-compatible); config supplied via
# `terraform init -backend-config=backend.tfvars` (see backend.tfvars.example).

terraform {
  backend "s3" {
  }
}