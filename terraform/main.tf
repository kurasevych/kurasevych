# 1. Variables
variable "do_token" {}
variable "ssh_public_key" {}
variable "last_name" { default = "kurasevych" }
variable "region"    { default = "fra1" }
variable "spaces_access_id" {}
variable "spaces_secret_key" {}

# 2. Terraform Settings & Backend
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

# 3. Provider
provider "digitalocean" {
  token             = var.do_token
  spaces_access_id  = var.spaces_access_id
  spaces_secret_key = var.spaces_secret_key
}

# 4. Resources
resource "digitalocean_vpc" "vpc" {
  name     = "kurasevych-vpc"
  region   = var.region
  ip_range = "10.10.10.0/24"
}

resource "digitalocean_ssh_key" "default" {
  name       = "kurasevych-key"
  public_key = var.ssh_public_key
}

resource "digitalocean_droplet" "node" {
  name     = "kurasevych-node"
  size     = "s-2vcpu-4gb"
  image    = "ubuntu-24-04-x64"
  region   = var.region
  vpc_uuid = digitalocean_vpc.vpc.id
  ssh_keys = [digitalocean_ssh_key.default.id]
}

resource "digitalocean_firewall" "firewall" {
  name        = "kurasevych-firewall"
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
  name   = "kurasevych-lab-bucket"
  region = var.region
  acl    = "private"
}

# 5. Output
output "droplet_ip" {
  value = digitalocean_droplet.node.ipv4_address
}
