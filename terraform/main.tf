# 1. Оголошення змінних (Важливо для отримання даних з GitHub Secrets)
variable "do_token" {
  description = "DigitalOcean API Token"
}

variable "ssh_public_key" {
  description = "Public SSH key for Droplet access"
}

variable "last_name" {
  description = "Student last name for resource naming"
  default     = "kurasevych"
}

variable "region" {
  description = "DigitalOcean region"
  default     = "fra1"
}

# Нові змінні для роботи зі Spaces (Object Storage)
variable "spaces_access_id" {
  description = "DigitalOcean Spaces Access Key"
}

variable "spaces_secret_key" {
  description = "DigitalOcean Spaces Secret Key"
}

# 2. Налаштування провайдера DigitalOcean
provider "digitalocean" {
  token = var.do_token

  # Ці параметри необхідні для створення бакета в Завданні 1
  spaces_access_id  = var.spaces_access_id
  spaces_secret_key = var.spaces_secret_key
}

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }

  # 3. Налаштування бекенду для зберігання стану в хмарі
  backend "s3" {
    endpoint                    = "https://fra1.digitaloceanspaces.com"
    bucket                      = "kurasevych-tfstate-backend"
    key                         = "terraform/state/terraform.tfstate"
    region                      = "us-east-1"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    force_path_style            = true
  }
}

# 4. Мережа (VPC) за завданням
resource "digitalocean_vpc" "vpc" {
  name     = "${var.last_name}-vpc"
  region   = var.region
  ip_range = "10.10.10.0/24"
}

# 5. SSH-ключ у DigitalOcean
resource "digitalocean_ssh_key" "default" {
  name       = "${var.last_name}-ssh-key"
  public_key = var.ssh_public_key
