resource "hcloud_server" "this" {
  name         = var.name
  image        = var.image
  server_type  = var.server_type
  location     = var.location
  ssh_keys     = var.ssh_key_ids
  firewall_ids = var.firewall_ids
  user_data    = var.user_data
  labels       = var.labels

  lifecycle {
    prevent_destroy = false
    # ignore_changes  = [user_data]
  }
}

resource "hcloud_server_network" "this" {
  server_id  = hcloud_server.this.id
  network_id = var.network_id
  ip         = var.private_ip
}
