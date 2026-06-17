moved {
  from = module.nodes["server_1"]
  to   = module.nodes["main_server"]
}

moved {
  from = module.nodes["worker_1"]
  to   = module.nodes["server_2"]
}

moved {
  from = module.nodes["worker_2"]
  to   = module.nodes["server_3"]
}

moved {
  from = hcloud_load_balancer_target.workers["worker_1"]
  to   = hcloud_load_balancer_target.servers["server_2"]
}

moved {
  from = hcloud_load_balancer_target.workers["worker_2"]
  to   = hcloud_load_balancer_target.servers["server_3"]
}
