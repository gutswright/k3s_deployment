variable "project_name" {
  description = "Project prefix used for Hetzner resource names and labels."
  type        = string
  default     = "rk4-k3s"
}

variable "location" {
  description = "Hetzner Cloud location for servers and load balancer."
  type        = string
  default     = "hil"
}

variable "network_zone" {
  description = "Hetzner private network zone. hil is in the us-west network zone."
  type        = string
  default     = "us-west"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key Terraform should register in Hetzner Cloud."
  type        = string
  default     = "~/.ssh/rk4_key.pub"
}

variable "ssh_port" {
  description = "Public SSH port configured on the servers."
  type        = number
  default     = 22
}

variable "ssh_allowed_cidrs" {
  description = "CIDR ranges allowed to SSH to the servers on ssh_port."
  type        = list(string)
}

variable "network_ip_range" {
  description = "CIDR range for the Hetzner private network."
  type        = string
  default     = "10.42.0.0/16"
}

variable "network_subnet_ip_range" {
  description = "CIDR range for the subnet used by this cluster."
  type        = string
  default     = "10.42.1.0/24"
}


variable "hcloud_token" {
  description = "Hetzner API project token that allows one to make changes to project via API access."
  type        = string
  sensitive   = true
}
