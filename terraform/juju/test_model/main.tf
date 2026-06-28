terraform {
  backend "s3" {
    bucket = "homelab-tfstate"
    key    = "juju/test_model/terraform.tfstate"
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
    juju = {
      source  = "juju/juju"
      version = "~> 2.1.0"
    }
  }
}

# Automatically uses the active 'homelab-controller' context
provider "juju" {}

resource "juju_model" "test_model" {
  name = "test-model"
}
