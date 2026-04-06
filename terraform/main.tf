terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Remote tfstate stored in GCS bucket (bootstrap bucket, created separately)
  backend "gcs" {
    bucket = "kurasevych-tfstate-backend"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ─────────────────────────────────────────────
# VPC
# ─────────────────────────────────────────────
resource "google_compute_network" "vpc" {
  name                    = "${var.last_name}-vpc"
  auto_create_subnetworks = false
  description             = "VPC for ${var.last_name} project"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.last_name}-subnet"
  ip_cidr_range = "10.10.10.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

# ─────────────────────────────────────────────
# Firewall
# ─────────────────────────────────────────────
resource "google_compute_firewall" "firewall" {
  name    = "${var.last_name}-firewall"
  network = google_compute_network.vpc.name

  # Inbound: allow specific ports
  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "8000", "8001", "8002", "8003"]
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["${var.last_name}-node"]
}

resource "google_compute_firewall" "firewall_egress" {
  name    = "${var.last_name}-firewall-egress"
  network = google_compute_network.vpc.name

  # Outbound: allow all ports 1-65535
  allow {
    protocol = "tcp"
    ports    = ["1-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["1-65535"]
  }

  direction          = "EGRESS"
  destination_ranges = ["0.0.0.0/0"]
  target_tags        = ["${var.last_name}-node"]
}

# ─────────────────────────────────────────────
# VM (meets Minikube requirements: 2 CPU, 4GB RAM)
# ─────────────────────────────────────────────
resource "google_compute_instance" "node" {
  name         = "${var.last_name}-node"
  machine_type = "e2-standard-2"   # 2 vCPU, 8 GB RAM — enough for Minikube
  zone         = "${var.region}-a"

  tags = ["${var.last_name}-node"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = 50  # GB
      type  = "pd-ssd"
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {
      # Ephemeral public IP
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${var.ssh_public_key}"
  }

  lifecycle {
    prevent_destroy = false
  }
}

# ─────────────────────────────────────────────
# Object Storage Bucket
# ─────────────────────────────────────────────
resource "google_storage_bucket" "bucket" {
  name          = "${var.last_name}-bucket"
  location      = var.region
  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 365
    }
  }
}
