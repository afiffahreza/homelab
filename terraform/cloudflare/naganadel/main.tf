terraform {
  backend "s3" {
    bucket = "homelab-tfstate"
    key    = "cloudflare/naganadel/terraform.tfstate"
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

resource "cloudflare_zero_trust_tunnel_cloudflared" "naganadel_ssh" {
  account_id      = var.cloudflare_account_id
  name            = "naganadel-ssh"
  tunnel_secret   = var.tunnel_secret
  config_src      = "cloudflare"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "naganadel_ssh_config" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.naganadel_ssh.id

  config = {
    ingress = [
      {
        hostname = "naganadel.drarso.xyz"
        service  = "ssh://localhost:22"
      },
      {
        service = "http_status:404"
      }
    ]
  }
}

resource "cloudflare_dns_record" "naganadel_ssh_dns" {
  zone_id = var.cloudflare_zone_id
  name    = "naganadel"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.naganadel_ssh.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "naganadel_ssh_token" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.naganadel_ssh.id
}

output "cloudflare_tunnel_token" {
  description = "The token used to authenticate the cloudflared daemon"
  value       = data.cloudflare_zero_trust_tunnel_cloudflared_token.naganadel_ssh_token.token
  sensitive   = true
}
