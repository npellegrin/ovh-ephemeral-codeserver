# Input variables for this stack; see terraform.tfvars.example.

variable "ovh_project_id" {
  description = "OVH Public Cloud project ID"
  type        = string
}

variable "region" {
  description = "OVH region for resource creation (for example, GRA, SBG, DE)"
  type        = string
  default     = "GRA"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}
