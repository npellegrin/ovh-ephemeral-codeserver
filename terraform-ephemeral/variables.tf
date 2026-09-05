# Input variables for this stack.

variable "ovh_project_id" {
  description = "Auto-populated by make from terraform-bootstrap's ovh_project_id output."
  type        = string
}

variable "compute_region" {
  description = "Auto-populated by make from terraform-bootstrap's compute_region output."
  type        = string
}

variable "keypair_name" {
  description = "Auto-populated by make from terraform-bootstrap's keypair_name output."
  type        = string
}

variable "instance_flavor" {
  description = "Instance flavor (for example, b3-8, b3-16, c3-8, or c3-16)"
  type        = string
  default     = "b3-8"
}

variable "instance_image" {
  description = "Base operating system image"
  type        = string
  default     = "Debian 12"
}

variable "volume_size_gb" {
  description = "Additional volume size in GB"
  type        = number
  default     = 40
}

variable "allowed_ssh_cidrs" {
  description = "CIDR ranges allowed for SSH (your public IP, /32)"
  type        = list(string)
  default     = [] # Required: no open default is provided.
}

variable "allowed_https_cidrs" {
  description = "CIDR ranges allowed for HTTPS (can be broader than SSH)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Public HTTPS by default; restrict if needed.
}

variable "allowed_http_cidrs" {
  description = "CIDR ranges allowed for HTTP (can be broader than SSH)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Public HTTP by default; restrict if needed.
}
