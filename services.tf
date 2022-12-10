locals {
  #  Replace this to match your container image
  artifacts = {
    image-url = "us-docker.pkg.dev/cloudrun/container"
  }
  image-name = "hello"
}

resource "google_cloud_run_service" "service" {
  name     = local.image-name
  location = var.region

  template {
    spec {
      container_concurrency = 1
      timeout_seconds       = 600

      containers {
        image = "${local.artifacts.image-url}/${local.image-name}"
      }
    }
  }

  metadata {
    annotations = {
      #    This sets the service to only allow internal and load balancer traffic
      "run.googleapis.com/ingress" = "internal-and-cloud-load-balancing"
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
  autogenerate_revision_name = true

  #  lifecycle {
  #    ignore_changes = [
  #      metadata.0.annotations,
  #    ]
  #  }
}

# We're not using Cloud IAM for authentication in this example. If you're using it in your service however, you can
# delete the following noauth blocks
data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_service.service.location
  project     = google_cloud_run_service.service.project
  service     = google_cloud_run_service.service.name
  policy_data = data.google_iam_policy.noauth.policy_data
}
