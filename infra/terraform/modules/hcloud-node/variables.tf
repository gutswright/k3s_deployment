variable "name" {
  type = string
}

variable "image" {
  type = string
}

variable "server_type" {
  type = string
}

variable "location" {
  type = string
}

variable "ssh_key_ids" {
  type = list(string)
}

variable "firewall_ids" {
  type = list(string)
}

variable "network_id" {
  type = string
}

variable "private_ip" {
  type = string
}

variable "labels" {
  type = map(string)
}

variable "user_data" {
  type      = string
  sensitive = true
}
