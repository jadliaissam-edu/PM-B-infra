# variables.tf
#
# This file defines all input variables used by Terraform.
# Every line is commented for beginner clarity.

variable "hcloud_token" {                 # Hetzner API token used by the provider.
  description = "Hetzner Cloud API token" # Short description.
  type        = string                    # Token is a string.
  sensitive   = true                      # Hide value in logs.
}                                         # End hcloud_token variable.

variable "ssh_public_key_path" {             # Path to the SSH public key file.
  description = "Path to the SSH public key" # Short description.
  type        = string                       # Path is a string.
}                                            # End ssh_public_key_path variable.

variable "ssh_private_key_path" {             # Path to the SSH private key file.
  description = "Path to the SSH private key" # Short description.
  type        = string                        # Path is a string.
}                                             # End ssh_private_key_path variable.

variable "location" {                              # Hetzner location where resources will be created.
  description = "Hetzner location (example: fsn1)" # Short description.
  type        = string                             # Location is a string.
  default     = "fsn1"                             # Default to Falkenstein.
}                                                  # End location variable.

variable "server_image" {               # Ubuntu image name used for servers.
  description = "Server image (Ubuntu)" # Short description.
  type        = string                  # Image is a string.
  default     = "ubuntu-22.04"          # Simple stable default.
}                                       # End server_image variable.

variable "app_count" {                  # Number of application servers.
  description = "Number of app servers" # Short description.
  type        = number                  # Count is a number.
  default     = 2                       # Two servers for high availability.
}                                       # End app_count variable.

variable "app_server_type" {                  # Size for app servers.
  description = "Hetzner server type for app" # Short description.
  type        = string                        # Type is a string.
  default     = "cpx22"                       # Simple and cost effective.
}                                             # End app_server_type variable.

variable "db_server_type" {                  # Size for db server.
  description = "Hetzner server type for db" # Short description.
  type        = string                       # Type is a string.
  default     = "cpx22"                      # Simple and cost effective.
}                                            # End db_server_type variable.

variable "ia_server_type" {                  # Size for IA server.
  description = "Hetzner server type for IA" # Short description.
  type        = string                       # Type is a string.
  default     = "cpx22"                      # Simple and cost effective.
}                                            # End ia_server_type variable.

variable "lb_type" {                         # Load balancer size.
  description = "Hetzner load balancer type" # Short description.
  type        = string                       # Type is a string.
  default     = "lb11"                       # Smallest LB for start.
}                                            # End lb_type variable.

variable "db_port" {            # Database port.
  description = "Database port" # Short description.
  type        = number          # Port is a number.
  default     = 5432            # Default Postgres port.
}                               # End db_port variable.
