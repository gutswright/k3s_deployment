locals {
  labels = {
    project = var.project_name
    managed = "terraform"
  }

  nodes = {
    main_server = {
      name_suffix = "main-server"
      private_ip  = "10.42.1.10"
      role        = "server"
      server_type = "cpx11"
    }
    server_2 = {
      name_suffix = "server-2"
      private_ip  = "10.42.1.12"
      role        = "server"
      server_type = "cpx11"
    }
    server_3 = {
      name_suffix = "server-3"
      private_ip  = "10.42.1.13"
      role        = "server"
      server_type = "cpx11"
    }
  }

  server_nodes = {
    for name, node in local.nodes : name => node
    if node.role == "server"
  }

  private_gateway = cidrhost(var.network_ip_range, 1)
  lb_private_ip   = "10.42.1.20"

  lb_services = {
    http      = 80
    https     = 443
    kube_port = 6443
  }

  private_cluster_firewall_rules = {
    tcp = {
      description = "Private cluster TCP traffic"
      port        = "any"
    }
    udp = {
      description = "Private cluster UDP traffic"
      port        = "any"
    }
    icmp = {
      description = "Private cluster ICMP traffic"
      port        = null
    }
  }
}
