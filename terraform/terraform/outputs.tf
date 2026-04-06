output "vpc_name" {
  description = "VPC network name"
  value       = google_compute_network.vpc.name
}

output "vm_public_ip" {
  description = "Public IP of the VM"
  value       = google_compute_instance.node.network_interface[0].access_config[0].nat_ip
}

output "vm_name" {
  description = "VM instance name"
  value       = google_compute_instance.node.name
}

output "bucket_name" {
  description = "Object storage bucket name"
  value       = google_storage_bucket.bucket.name
}

output "bucket_url" {
  description = "Bucket URL"
  value       = google_storage_bucket.bucket.url
}
