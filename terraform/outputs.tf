# outputs.tf
#
# This file exposes outputs after `terraform apply`.
# Every line is commented for beginner clarity.

output "load_balancer_ip" { # Public IP for the load balancer.
	description = "Public IP of the load balancer" # Short description.
	value       = hcloud_load_balancer.lb.ipv4 # IPv4 address of LB.
} # End load_balancer_ip output.

output "app_public_ips" { # Public IPs of app servers.
	description = "Public IPs of app servers" # Short description.
	value       = hcloud_server.app[*].ipv4_address # List of app IPs.
} # End app_public_ips output.

output "db_public_ip" { # Public IP of db server.
	description = "Public IP of db server" # Short description.
	value       = hcloud_server.db.ipv4_address # DB IP.
} # End db_public_ip output.

output "ia_public_ip" { # Public IP of IA server.
	description = "Public IP of IA server" # Short description.
	value       = hcloud_server.ia.ipv4_address # IA IP.
} # End ia_public_ip output.

output "ia_load_balancer_ip" { # Public IP of IA load balancer.
	description = "Public IP of IA load balancer" # Short description.
	value       = hcloud_load_balancer.ia_lb.ipv4 # IA LB IP.
} # End ia_load_balancer_ip output.
