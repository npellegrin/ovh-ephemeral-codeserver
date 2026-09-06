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

variable "create_security_group" {
  description = "Create a dedicated OpenStack security group with allowed_*_cidrs rules below. Defaults to false: new/unverified OVH accounts get a security_group quota of 0. Flip to true once your account's quota allows creating security groups."
  type        = bool
  default     = false
}

variable "allowed_ssh_cidrs" {
  description = "CIDR ranges allowed for SSH. Only used when create_security_group is true; leaving it empty then blocks SSH at the OpenStack layer entirely."
  type        = list(string)
  default     = []
}

variable "allowed_https_cidrs" {
  description = "CIDR ranges allowed for HTTPS. Only used when create_security_group is true."
  type        = list(string)
  default     = ["0.0.0.0/0"] # Public HTTPS by default; restrict if needed.
}

variable "allowed_http_cidrs" {
  description = "CIDR ranges allowed for HTTP. Only used when create_security_group is true."
  type        = list(string)
  default     = ["0.0.0.0/0"] # Public HTTP by default; restrict if needed.
}

variable "manage_dns" {
  description = "Create/update an A record in an OVH DNS zone pointing at the instance IP. false: point DNS yourself (make create pauses to let you do it)."
  type        = bool
  default     = false
}

variable "dns_zone" {
  description = "OVH DNS zone, e.g. example.com. Required when manage_dns = true."
  type        = string
  default     = ""
}

variable "dns_subdomain" {
  description = "Record name within the zone, e.g. code for code.example.com. Must match ansible domain_name. Empty targets the apex."
  type        = string
  default     = ""
}

variable "dns_ttl" {
  description = "TTL (seconds) for the managed A record."
  type        = number
  default     = 60
}
