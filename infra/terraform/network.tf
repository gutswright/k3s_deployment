resource "hcloud_ssh_key" "main" {
  name       = "${var.project_name}-admin"
  public_key = file(pathexpand(var.ssh_public_key_path))
  labels     = local.labels
}

resource "hcloud_network" "main" {
  name     = "${var.project_name}-net"
  ip_range = var.network_ip_range
  labels   = local.labels
}

resource "hcloud_network_subnet" "main" {
  network_id   = hcloud_network.main.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = var.network_subnet_ip_range
}
