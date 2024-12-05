resource "digitalocean_vpc" "example_vpc" {
  name     = "oskar-vpc"
  region   = "fra1"
  ip_range = "10.1.0.0/16"
}

resource "digitalocean_project" "example_project" {
  name        = "oskar-project"
  purpose     = "Test App"
  environment = "Development"
}

resource "tls_private_key" "example_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "digitalocean_ssh_key" "example_ssh_key" {
  name       = "example-ssh-key"
  public_key = tls_private_key.example_key.public_key_openssh
}

resource "digitalocean_droplet" "droplet_ubuntu_22" {
  name       = "uczen-Oskar-Mierkiewicz"
  image      = "ubuntu-22-04-x64"
  region     = "fra1"
  size       = "s-1vcpu-1gb"
  ssh_keys   = [digitalocean_ssh_key.example_ssh_key.id]
  vpc_uuid   = digitalocean_vpc.example_vpc.id

  user_data = <<-EOT
    #cloud-config
    packages:
      - nginx
    runcmd:
      - echo "<h1>Welcome to Ubuntu 22.04</h1>" > /var/www/html/index.html
      - systemctl restart nginx
  EOT

  tags = ["example-tag"]
}

resource "digitalocean_firewall" "incoming_firewall" {
  name = "incoming-firewall"

  dynamic "inbound_rule" {
    for_each = [
      { protocol = "tcp", port_range = "22", source = var.my_ip },
      { protocol = "tcp", port_range = "80", source = "0.0.0.0/0" },
      { protocol = "tcp", port_range = "443", source = "0.0.0.0/0" },
    ]

    content {
      protocol   = inbound_rule.value.protocol
      port_range = inbound_rule.value.port_range
      source_addresses = [inbound_rule.value.source]
    }
  }

  droplet_ids = [digitalocean_droplet.droplet_ubuntu_22.id]
}

resource "digitalocean_firewall" "outgoing_firewall" {
  name = "outgoing-firewall"

  outbound_rule {
    protocol         = "tcp"
    port_range       = "all"
    destination_addresses = ["0.0.0.0/0"]
  }

  outbound_rule {
    protocol         = "udp"
    port_range       = "all"
    destination_addresses = ["0.0.0.0/0"]
  }

  outbound_rule {
    protocol         = "icmp"
    destination_addresses = ["0.0.0.0/0"]
  }

  droplet_ids = [digitalocean_droplet.droplet_ubuntu_22.id]
}

resource "digitalocean_domain" "example_domain" {
  name = var.fqdn
}

resource "digitalocean_record" "example_record" {
  domain = digitalocean_domain.example_domain.name
  type   = "A"
  name   = "@"
  value  = digitalocean_droplet.droplet_ubuntu_22.ipv4_address
  ttl    = 3600
}