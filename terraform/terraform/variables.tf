variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "GCP region closest to Ukraine (Warsaw, Poland)"
  type        = string
  default     = "europe-central2"  # Warsaw — closest GCP region to Ukraine
}

variable "last_name" {
  description = "Your last name used in resource naming"
  type        = string
  default     = "kurasevych"
}

variable "ssh_user" {
  description = "SSH username for the VM"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access (injected via CI/CD secret)"
  type        = string
  sensitive   = true
}
