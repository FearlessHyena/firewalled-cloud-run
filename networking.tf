locals {
  ip = {
    authorized = [
      # Add your list of IPs to whitelist here in CIDR format
    ]
  }

  domain = "<YOUR_DOMAIN_NAME>"
}

resource "google_compute_global_address" "service-lb-ip" {
  name = "${local.image-name}-lb-ip"
}

resource "google_compute_region_network_endpoint_group" "serverless-neg" {
  name                  = "${local.image-name}-serverless-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = google_cloud_run_service.service.name
  }
}

resource "google_compute_security_policy" "security-policy" {
  name = "${local.image-name}-security"

  rule {
    action   = "allow"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = local.ip.authorized
      }
    }
    description = "Allow access to authorized IPs only"
  }

  rule {
    action   = "deny(403)"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "default deny rule"
  }
}

module "service-loadbalancer" {
  source  = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  version = "~> 6.0"
  name    = "${local.image-name}-service"
  project = var.project

  address        = google_compute_global_address.service-lb-ip.address
  create_address = false

  #  if you're using ssl and have a domain go ahead and set this to true and uncomment the following lines
  ssl = false
  #  managed_ssl_certificate_domains = [local.domain]
  #  https_redirect                  = true

  backends = {
    default = {
      description = null
      groups = [
        {
          group = google_compute_region_network_endpoint_group.serverless-neg.id
        }
      ]
      enable_cdn              = false
      security_policy         = null
      custom_request_headers  = null
      custom_response_headers = null
      security_policy         = google_compute_security_policy.security-policy.id

      iap_config = {
        enable               = false
        oauth2_client_id     = ""
        oauth2_client_secret = ""
      }
      log_config = {
        enable      = false
        sample_rate = null
      }
    }
  }
}

output "cloud-run-load-balancer-ip" {
  value = google_compute_global_address.service-lb-ip.address
}