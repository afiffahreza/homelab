variable "admin_email" {
  description = "The email address allowed to access Grafana via Cloudflare OTP"
  type        = string
}

variable "cloudflare_api_token" {
  description = "API Token for Cloudflare"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID (for your specific domain)"
  type        = string
}

variable "tunnel_secret" {
  description = "A 32-byte base64 encoded secret for the tunnel"
  type        = string
  sensitive   = true
}
