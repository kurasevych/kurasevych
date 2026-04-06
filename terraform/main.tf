# 1. Оголошення змінних
variable "do_token" {}
variable "ssh_public_key" {}
variable "last_name" { default = "kurasevych" } # Прізвище латиницею без пробілів
variable "region"    { default = "fra1" }
variable "spaces_access_id" {}
variable "spaces_secret_key" {}

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
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

provider "digitalocean" {
  token             = var.do_token
  spaces_access_id  = var.spaces_access_id
  spaces_secret_key = var.spaces_secret_key
}

# 2. VPC (Назва тепер без зайвих символів)
resource "digitalocean_vpc" "vpc" {
  name     = "vpc-${var.last_name}" 
  region   = var.region
  ip_range = "10.10.10.0/24"
}

# 3. SSH Key
resource "digitalocean_ssh_key" "default" {
  name       = "key-${var.last_name}"
  public_key = var.ssh_public_key
}

# 4. Droplet
resource "digitalocean_droplet" "node" {
  name     = "node-${var.last_name}"
  size     = "s-2vcpu-4gb"
  image    = "ubuntu-24-04-x64"
  region   = var.region
  vpc_uuid = digitalocean_vpc.vpc.id
  ssh_keys = [digitalocean_ssh_key.default.id]
}

# 5. Firewall
resource "digitalocean_firewall" "firewall" {
  name = "fw-${var.last_name}"
  droplet_ids = [digitalocean_droplet.node.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "8000-8003"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# 6. Spaces Bucket (Назва має бути дуже специфічною)
resource "digitalocean_spaces_bucket" "bucket" {
  name   = "bucket-${var.last_name}-unique-id" # Змінив на більш унікальну
  region = var.region
  acl    = "private"
  versioning {
    enabled = true
  }
}

output "droplet_ip" {
  value = digitalocean_droplet.node.ipv4_address
}
