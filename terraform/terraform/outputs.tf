output "vpc_name" {
  description = "VPC name"
  value       = digitalocean_vpc.vpc.name
}

output "droplet_ip" {
  description = "Публічна IP-адреса VM"
  value       = digitalocean_droplet.node.ipv4_address
}

output "droplet_name" {
  description = "Назва VM"
  value       = digitalocean_droplet.node.name
}

output "bucket_name" {
  description = "Назва bucket"
  value       = digitalocean_spaces_bucket.bucket.name
}

output "bucket_domain" {
  description = "Домен bucket"
  value       = digitalocean_spaces_bucket.bucket.bucket_domain_name
}
