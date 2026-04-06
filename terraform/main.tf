# 1. Оголошення змінних (Критично важливо!)
variable "do_token" {}
variable "ssh_public_key" {}
variable "last_name" {
  default = "kurasevych"
}
variable "region" {
  default = "fra1"
}

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }

  # 2. Налаштування бекенду
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
  token = var.do_token
}

# 3. Мережа (VPC)
resource "digitalocean_vpc" "vpc" {
  name     = "${var.last_name}-vpc"
  region   = var.region
  ip_range = "10.10.10.0/24"
}

# 4. SSH-ключ
resource "digitalocean_ssh_key" "default" {
  name       = "${var.last_name}-ssh-key"
  public_key = var.ssh_public_key
}

# 5. Віртуальна машина (Droplet)
resource "digitalocean_droplet" "node" {
  name     = "${var.last_name}-node"
  size     = "s-2vcpu-4gb"
  image    = "ubuntu-24-04-x64"
  region   = var.region
  vpc_uuid = digitalocean_vpc.vpc.id
  ssh_keys = [digitalocean_ssh_key.default.id]

  tags = ["${var.last_name}-node"]
}

# 6. Фаєрвол
resource "digitalocean_firewall" "firewall" {
  name = "${var.last_name}-firewall"

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

# 7. Бакет
resource "digitalocean_spaces_bucket" "bucket" {
  name   = "${var.last_name}-bucket"
  region = var.region
  acl    = "private"

  versioning {
    enabled = true
  }
}

# 8. Вивід IP
output "droplet_ip" {
  value = digitalocean_droplet.node.ipv4_address
}
