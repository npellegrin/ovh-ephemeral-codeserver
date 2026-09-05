# Remote state in OVH Object Storage (S3-compatible); config supplied via
# `terraform init -backend-config=backend.tfvars`.

terraform {
  backend "s3" {
  }
}