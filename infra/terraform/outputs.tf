output "server_public_ips" {
  description = "Public IPv4 addresses for SSH access."
  value = {
    for name, node in module.nodes : name => node.public_ipv4
  }
}

output "server_private_ips" {
  description = "Private IPv4 addresses used for k3s and service traffic."
  value = {
    for name, node in module.nodes : name => node.private_ipv4
  }
}

output "load_balancer_public_ipv4" {
  description = "Public IPv4 address for DNS A records."
  value       = hcloud_load_balancer.web.ipv4
}

output "load_balancer_private_ipv4" {
  description = "Private IPv4 address used by the load balancer on the Hetzner network."
  value       = local.lb_private_ip
}
