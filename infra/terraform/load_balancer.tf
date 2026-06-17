resource "hcloud_load_balancer" "web" {
  name               = "${var.project_name}-lb-1"
  load_balancer_type = "lb11"
  location           = var.location
  labels             = local.labels
}

resource "hcloud_load_balancer_network" "web" {
  load_balancer_id = hcloud_load_balancer.web.id
  network_id       = hcloud_network.main.id
  ip               = local.lb_private_ip

  depends_on = [
    hcloud_network_subnet.main
  ]
}

resource "hcloud_load_balancer_target" "servers" {
  for_each = local.server_nodes

  type             = "server"
  load_balancer_id = hcloud_load_balancer.web.id
  server_id        = module.nodes[each.key].server_id
  use_private_ip   = true

  depends_on = [
    hcloud_load_balancer_network.web,
    module.nodes
  ]
}

resource "hcloud_load_balancer_service" "web" {
  for_each = local.lb_services

  load_balancer_id = hcloud_load_balancer.web.id
  protocol         = "tcp"
  listen_port      = each.value
  destination_port = each.value

  health_check {
    protocol = "tcp"
    port     = each.value
    interval = 15
    timeout  = 10
    retries  = 3
  }
}
