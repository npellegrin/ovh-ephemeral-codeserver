# Input variables for this stack; see terraform.tfvars.example.

variable "ovh_project_id" {
  description = "OVH Public Cloud project ID"
  type        = string
}

variable "object_storage_region" {
  description = "OVH Object Storage region"
  type        = string
  default     = "GRA"
}

variable "compute_region" {
  description = "OVH Compute/Network region"
  type        = string
  default     = "GRA11"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}
