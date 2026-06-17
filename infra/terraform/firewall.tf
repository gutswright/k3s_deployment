resource "hcloud_firewall" "servers" {
  name   = "${var.project_name}-servers"
  labels = local.labels

  rule {
    description = "SSH from approved client IP ranges"
    direction   = "in"
    protocol    = "tcp"
    port        = tostring(var.ssh_port)
    source_ips  = var.ssh_allowed_cidrs
  }

  dynamic "rule" {
    for_each = local.private_cluster_firewall_rules

    content {
      description = rule.value.description
      direction   = "in"
      protocol    = rule.key
      port        = rule.value.port
      source_ips  = [var.network_ip_range]
    }
  }
}
