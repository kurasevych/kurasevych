terraform {
  required_version = ">= 1.5.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }

  # Remote tfstate stored in DigitalOcean Spaces
  # Виправлено для сумісності з GitHub Actions та DigitalOcean API
  backend "s3" {
    endpoint                    = "https://fra1.digitaloceanspaces.com" # Додано https://
    bucket                      = "kurasevych-tfstate-backend"
    key                         = "terraform/state/terraform.tfstate"
    region                      = "us-east-1" # Placeholder для S3 backend
    
    # Критичні параметри для роботи з DO Spaces замість реального AWS:
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    force_path_style            = true
  }
}

provider "digitalocean" {
  token = var.do_token
}

# ─────────────────────────────────────────────
# VPC
# ─────────────────────────────────────────────
resource "digitalocean_vpc" "vpc" {
  name     = "${var.last_name}-vpc"
  region   = var.region
  ip_range = "10.10.10.0/24"
}

# ─────────────────────────────────────────────
# Firewall
# ─────────────────────────────────────────────
resource "digitalocean_firewall" "firewall" {
  name = "${var.last_name}-firewall"

  droplet_ids = [digitalocean_droplet.node.id]

  # Inbound: дозволені порти за завданням
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

  # Outbound: всі порти 1-65535 за завданням
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
