variable "do_token" {
  description = "DigitalOcean API Token"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "DigitalOcean region (Frankfurt — найближчий до України)"
  type        = string
  default     = "fra1"  # Frankfurt
}

variable "last_name" {
  description = "Прізвище для назв ресурсів"
  type        = string
  default     = "kurasevych"
}

variable "ssh_public_key" {
  description = "Публічний SSH ключ для доступу до VM"
  type        = string
  sensitive   = true
}

variable "spaces_access_id" {
  description = "DigitalOcean Spaces Access Key ID"
  type        = string
  sensitive   = true
}

variable "spaces_secret_key" {
  description = "DigitalOcean Spaces Secret Key"
  type        = string
  sensitive   = true
}
