terraform {
  required_version = "~> 1.0"

  required_providers {
    google = "~> 4.0"
  }
}

provider "google" {
  project = var.project
  region  = var.region
}
