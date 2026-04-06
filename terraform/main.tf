terraform {
  required_version = ">= 1.5.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }

  # Remote tfstate stored in DigitalOcean Spaces
  backend "s3" {
    endpoint                    = "fra1.digitaloceanspaces.com"
    bucket                      = "kurasevych-tfstate-backend"
    key                         = "terraform/state/terraform.tfstate"
    region                      = "us-east-1" # placeholder, required by S3 backend
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
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

  # Inbound: дозволені порти
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

  # Outbound: всі порти 1-65535
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
}

# ─────────────────────────────────────────────
# SSH Key
# ─────────────────────────────────────────────
resource "digitalocean_ssh_key" "default" {
  name       = "${var.last_name}-ssh-key"
  public_key = var.ssh_public_key
}

# ─────────────────────────────────────────────
# VM (Droplet) — відповідає вимогам Minikube
# s-2vcpu-4gb: 2 vCPU, 4 GB RAM
# ─────────────────────────────────────────────
resource "digitalocean_droplet" "node" {
  name     = "${var.last_name}-node"
  size     = "s-2vcpu-4gb"   # 2 vCPU, 4 GB RAM — мінімум для Minikube
  image    = "ubuntu-24-04-x64"
  region   = var.region
  vpc_uuid = digitalocean_vpc.vpc.id
  ssh_keys = [digitalocean_ssh_key.default.fingerprint]

  tags = ["${var.last_name}-node"]
}

# ─────────────────────────────────────────────
# Object Storage (Spaces bucket)
# ─────────────────────────────────────────────
resource "digitalocean_spaces_bucket" "bucket" {
  name   = "${var.last_name}-bucket"
  region = var.region
  acl    = "private"

  versioning {
    enabled = true
  }
}
output "droplet_ip" {
  value = digitalocean_droplet.node.ipv4_address
}
