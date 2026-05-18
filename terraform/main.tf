# main.tf
# This file defines the Hetzner Cloud resources for phase 1.

terraform {                           # Start Terraform settings block.
  required_version = ">= 1.5.0"       # Require a modern Terraform version.
  required_providers {                # Define the providers we will use.
    hcloud = {                        # Hetzner Cloud provider block.
      source  = "hetznercloud/hcloud" # Provider source address.
      version = ">= 1.48.0"           # Provider version constraint.
    }
    local = {                     # Local provider for generated files.
      source  = "hashicorp/local" # Provider source address.
      version = ">= 2.5.0"        # Provider version constraint.
    }
  }
}

provider "hcloud" {        # Configure the Hetzner provider.
  token = var.hcloud_token # API token read from variables.
}

resource "hcloud_ssh_key" "project_key" {    # Register SSH public key in Hetzner.
  name       = "pm-b-infra-key"              # Name visible in Hetzner UI.
  public_key = file(var.ssh_public_key_path) # Read public key from local path.
}                                            # End SSH key resource.

resource "hcloud_firewall" "app_fw" {  # Firewall for application servers.
  name = "pm-b-app-fw"                 # Friendly name for the firewall.
  rule {                               # Allow inbound SSH.
    direction  = "in"                  # Inbound traffic rule.
    protocol   = "tcp"                 # TCP protocol.
    port       = "22"                  # SSH port.
    source_ips = ["0.0.0.0/0", "::/0"] # Allow SSH from anywhere (simple start).
  }                                    # End SSH rule.
  rule {                               # Allow inbound HTTP.
    direction  = "in"                  # Inbound traffic rule.
    protocol   = "tcp"                 # TCP protocol.
    port       = "80"                  # HTTP port.
    source_ips = ["0.0.0.0/0", "::/0"] # Allow HTTP from anywhere.
  }                                    # End HTTP rule.
}                                      # End app firewall.

resource "hcloud_firewall" "db_fw" {               # Firewall for database server.
  name = "pm-b-db-fw"                              # Friendly name for the firewall.
  rule {                                           # Allow inbound SSH.
    direction  = "in"                              # Inbound traffic rule.
    protocol   = "tcp"                             # TCP protocol.
    port       = "22"                              # SSH port.
    source_ips = ["0.0.0.0/0", "::/0"]             # Allow SSH from anywhere (simple start).
  }                                                # End SSH rule.
  rule {                                           # Allow inbound DB traffic from app servers only.
    direction  = "in"                              # Inbound traffic rule.
    protocol   = "tcp"                             # TCP protocol.
    port       = var.db_port                       # Database port (default 5432).
    source_ips = hcloud_server.app[*].ipv4_address # Allow only app server IPs.
  }                                                # End DB rule.
}                                                  # End db firewall.

resource "hcloud_server" "app" {                 # Create the application servers.
  count        = var.app_count                   # Number of app servers.
  name         = "pm-b-app-${count.index + 1}"   # Unique name per server.
  server_type  = var.app_server_type             # Size of the app servers.
  image        = var.server_image                # Ubuntu image to use.
  location     = var.location                    # Hetzner location.
  ssh_keys     = [hcloud_ssh_key.project_key.id] # Attach SSH key.
  firewall_ids = [hcloud_firewall.app_fw.id]     # Attach app firewall.
}                                                # End app server resource.

resource "hcloud_server" "db" {                  # Create the database server.
  name         = "pm-b-db-1"                     # Single DB server name.
  server_type  = var.db_server_type              # Size of the DB server.
  image        = var.server_image                # Ubuntu image to use.
  location     = var.location                    # Hetzner location.
  ssh_keys     = [hcloud_ssh_key.project_key.id] # Attach SSH key.
  firewall_ids = [hcloud_firewall.db_fw.id]      # Attach db firewall.
}                                                # End db server resource.

resource "hcloud_firewall" "ia_fw" {   # Firewall for IA server.
  name = "pm-b-ia-fw"                  # Friendly name for the IA firewall.
  rule {                               # Allow inbound SSH.
    direction  = "in"                  # Inbound traffic rule.
    protocol   = "tcp"                 # TCP protocol.
    port       = "22"                  # SSH port.
    source_ips = ["0.0.0.0/0", "::/0"] # Allow SSH from anywhere.
  }                                    # End SSH rule.
  rule {                               # Allow inbound IA API traffic.
    direction  = "in"                  # Inbound traffic rule.
    protocol   = "tcp"                 # TCP protocol.
    port       = "8000"                # IA API port.
    source_ips = ["0.0.0.0/0", "::/0"] # Allow API from anywhere.
  }                                    # End IA rule.
}                                      # End ia firewall.

resource "hcloud_server" "ia" {                  # Create the IA server.
  name         = "pm-b-ia-1"                     # Single IA server name.
  server_type  = var.ia_server_type              # Size of the IA server.
  image        = var.server_image                # Ubuntu image to use.
  location     = var.location                    # Hetzner location.
  ssh_keys     = [hcloud_ssh_key.project_key.id] # Attach SSH key.
  firewall_ids = [hcloud_firewall.ia_fw.id]      # Attach IA firewall.
}                                                # End ia server resource.

resource "hcloud_load_balancer" "ia_lb" { # Load balancer for IA.
  name               = "pm-b-ia-lb"       # IA load balancer name.
  load_balancer_type = var.lb_type        # Reuse default LB size.
  location           = var.location       # Hetzner location.
}                                         # End IA load balancer resource.

resource "hcloud_load_balancer_service" "ia_http" { # IA service on port 8000.
  load_balancer_id = hcloud_load_balancer.ia_lb.id  # Target IA LB id.
  protocol         = "http"                         # HTTP protocol.
  listen_port      = 8000                           # Public port.
  destination_port = 8000                           # Forward to IA service port.

  health_check {      # Ensure IA target is marked healthy.
    protocol = "http" # HTTP health check.
    port     = 8000   # Check IA port.
    interval = 15     # Seconds between checks.
    timeout  = 10     # Seconds before timeout.
    retries  = 3      # Retries before marking unhealthy.
    http {
      path         = "/docs" # FastAPI docs returns 200.
      status_codes = ["2??", "3??"]
    }
  }
} # End IA LB service.

resource "hcloud_load_balancer_service" "ia_https" { # IA service on port 443.
  load_balancer_id = hcloud_load_balancer.ia_lb.id   # Target IA LB id.
  protocol         = "https"                         # HTTPS protocol.
  listen_port      = 443                             # Public port.
  destination_port = 8000                            # Forward to IA service port.

  http {
    certificates = [data.hcloud_certificate.mon_certificat_fixe.id]
  }

  health_check {
    protocol = "http"
    port     = 8000
    interval = 15
    timeout  = 10
    retries  = 3
    http {
      path         = "/docs"
      status_codes = ["2??", "3??"]
    }
  }
} # End IA HTTPS service.

resource "hcloud_load_balancer_target" "ia_target" { # Attach IA server to IA LB.
  type             = "server"                        # Target type is a server.
  load_balancer_id = hcloud_load_balancer.ia_lb.id   # IA LB id.
  server_id        = hcloud_server.ia.id             # IA server id.
}                                                    # End IA LB target.

resource "hcloud_load_balancer" "lb" { # Create the load balancer.
  name               = "pm-b-lb"       # Load balancer name.
  load_balancer_type = var.lb_type     # Load balancer size.
  location           = var.location    # Hetzner location.
}                                      # End load balancer resource.

# Temporary http config 
resource "hcloud_load_balancer_service" "http" {
  load_balancer_id = hcloud_load_balancer.lb.id
  protocol         = "http"
  listen_port      = 80
  destination_port = 80
}

# ===================================================================================

# 1. On récupère le certificat persistant créé manuellement dans la console
data "hcloud_certificate" "mon_certificat_fixe" {
  name = "managed-certificate-1" 
  # Ou utilisez un filtre si vous n'avez pas mis de nom spécifique :
  # with_selector = "app=prod"
}

# 2. On attache ce certificat au service HTTPS du Load Balancer
resource "hcloud_load_balancer_service" "https_service" {
  load_balancer_id = hcloud_load_balancer.lb.id
  protocol         = "https"
  listen_port      = 443
  destination_port = 80 # Le port sur lequel vos conteneurs écoutent

  http {
    # On injecte l'ID du certificat récupéré par le bloc data
    certificates = [data.hcloud_certificate.mon_certificat_fixe.id]
  }
}

# ===================================================================================



# # TEMP: Certificate disabled to avoid Let's Encrypt duplicate rate limit.
# # Uncomment once the rate limit window resets.
# resource "hcloud_managed_certificate" "letsencrypt" { # Managed SSL cert (Let's Encrypt).
# 	name         = "orbytee.tech-ssl" # Friendly name in Hetzner.
# 	domain_names = ["orbytee.tech", "www.orbytee.tech"] # Domains for HTTPS.
# }

# resource "hcloud_load_balancer_service" "https" { # Configure LB service on HTTPS.
# 	load_balancer_id = hcloud_load_balancer.lb.id # Target LB id.
# 	protocol         = "https" # HTTPS protocol.
# 	listen_port      = 443 # Port on the LB.
# 	destination_port = 80 # Forward to app servers over HTTP.

# 	# HTTPS + redirection HTTP -> HTTPS, gere par le load balancer.
# 	http {
# 		certificates  = [hcloud_managed_certificate.letsencrypt.id]
# 		redirect_http = true
# 	}
# }

resource "hcloud_load_balancer_target" "app_targets" { # Attach app servers to LB.
  count            = var.app_count                     # One target per app server.
  type             = "server"                          # Target type is a server.
  load_balancer_id = hcloud_load_balancer.lb.id        # Target LB id.
  server_id        = hcloud_server.app[count.index].id # Target app server id.
}                                                      # End LB targets.

resource "local_file" "inventory" {                    # Generate the Ansible inventory from Terraform outputs.
  filename = "${path.module}/../ansible/inventory.ini" # Keep the existing inventory path.
  content  = <<-EOT
# inventory.ini
#
# This is a simple static inventory for beginners.
# Replace the IPs with the outputs from Terraform.

[app]
# Two application servers (example IPs below).
app1 ansible_host=${hcloud_server.app[0].ipv4_address}
app2 ansible_host=${hcloud_server.app[1].ipv4_address}

[db]
# One database server (example IP below).
db1 ansible_host=${hcloud_server.db.ipv4_address}

[ia]
# One IA server (replace with Terraform output ia_public_ip).
ia1 ansible_host=${hcloud_server.ia.ipv4_address}

[all:vars]
# Default SSH user (Hetzner Ubuntu images use root).
ansible_user=root
# Path to your private key (WSL path, adjust if needed).
ansible_ssh_private_key_file="~/.ssh/pm-b-infra"
# Disable host key checking for first time setup (simple start).
ansible_ssh_common_args="-o StrictHostKeyChecking=no"
EOT
} # End inventory file generation.
