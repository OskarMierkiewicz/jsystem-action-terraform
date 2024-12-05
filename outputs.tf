output "droplet_ip" {
  value = digitalocean_droplet.droplet_ubuntu_22.ipv4_address
}

output "ssh_private_key" {
  value     = tls_private_key.example_key.private_key_pem
  sensitive = true
}