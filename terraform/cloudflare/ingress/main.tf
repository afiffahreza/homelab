terraform {
  backend "s3" {
    bucket = "homelab-tfstate"
    key    = "cloudflare/ingress/terraform.tfstate"
    region = "auto"
    
    endpoints = {
      s3 = "https://f0a809b662083371772d347d2acdad2a.r2.cloudflarestorage.com"
    }

    # Enable OpenTofu native S3 locking
    use_lockfile = true 

    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
  }
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "ingress" {
  account_id      = var.cloudflare_account_id
  name            = "ingress"
  tunnel_secret   = var.tunnel_secret
  config_src      = "cloudflare"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "ingress_config" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.ingress.id

  config = {
    ingress = [
      {
        hostname = "grafana.drarso.xyz"
        service  = "http://vm-stack-grafana.monitoring.svc.cluster.local:80"
      },
      # Catch-all rule for unmatched traffic (required by Cloudflare)
      {
        service = "http_status:404"
      }
    ]
  }
}

# Automatically create CNAME records for every service routed through the tunnel
resource "cloudflare_dns_record" "ingress_cnames" {
  for_each = toset(["grafana"])

  zone_id = var.cloudflare_zone_id
  name    = each.key
  content = "${cloudflare_zero_trust_tunnel_cloudflared.ingress.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

# Define the Access Application for the specific subdomain
resource "cloudflare_zero_trust_access_application" "grafana" {
  zone_id              = var.cloudflare_zone_id
  name                 = "Grafana Homelab"
  domain               = "grafana.drarso.xyz"
  type                 = "self_hosted"
  session_duration     = "24h"
  app_launcher_visible = true

  policies = [{
    name       = "Allow Admin"
    decision   = "allow"
    precedence = 1
    
    include = [{
      email = {
        email = var.admin_email
      }
    }]
  }]
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "ingress_token" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.ingress.id
}

output "cloudflare_tunnel_token" {
  description = "The token used to authenticate the cloudflared daemon"
  value       = data.cloudflare_zero_trust_tunnel_cloudflared_token.ingress_token.token
  sensitive   = true
}
