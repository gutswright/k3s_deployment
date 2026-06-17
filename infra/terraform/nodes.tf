module "nodes" {
  source   = "./modules/hcloud-node"
  for_each = local.nodes

  name         = "${var.project_name}-${each.value.name_suffix}"
  image        = "ubuntu-24.04"
  server_type  = each.value.server_type
  location     = var.location
  ssh_key_ids  = [hcloud_ssh_key.main.id]
  firewall_ids = [hcloud_firewall.servers.id]
  network_id   = hcloud_network.main.id
  private_ip   = each.value.private_ip
  labels = merge(local.labels, {
    role = "k3s-${each.value.role}"
  })

  user_data = templatefile("${path.module}/bootstrap/base-cloud-init.yaml.tftpl", {
    ssh_port             = var.ssh_port
    private_ip           = each.value.private_ip
    private_gateway      = local.private_gateway
    private_network_cidr = var.network_ip_range
  })
}
