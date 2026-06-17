output "server_id" {
  value = hcloud_server.this.id
}

output "public_ipv4" {
  value = hcloud_server.this.ipv4_address
}

output "private_ipv4" {
  value = var.private_ip
}

output "network_attachment_id" {
  value = hcloud_server_network.this.id
}
