variable "do_token" {}
variable "ssh_public_key" {}
variable "last_name" { default = "kurasevych" }
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
    region                      = "us-east-1" # Порт для S3 сумісності
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

# 1. Мережа
resource "digitalocean_vpc" "vpc" {
  name     = "kurasevych-vpc"
  region   = var.region
  ip_range = "10.10.10.0/24"
}

# 2. Ключ
resource "digitalocean_ssh_key" "default" {
  name       = "kurasevych-ssh-key"
  public_key = var.ssh_public_key
}

# 3. Сервер (Droplet)
resource "digitalocean_droplet" "node" {
  name     = "kurasevych-node"
  size     = "s-2vcpu-4gb"
  image    = "ubuntu-24-04-x64"
  region   = var.region
  vpc_uuid = digitalocean_vpc.vpc.id
  ssh_keys = [digitalocean_ssh_key.default.id]
}

# 4. Фаєрвол
resource "digitalocean_firewall" "firewall" {
  name = "kurasevych-firewall"
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

resource "digitalocean_spaces_bucket" "bucket" {
  name   = "kurasevych-lab-final-storage-v3" # Зміни назву на цю
  region = var.region
  acl    = "private"
}

output "droplet_ip" {
  value = digitalocean_droplet.node.ipv4_address
}
