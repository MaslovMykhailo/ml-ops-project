# Label Studio Module Outputs

output "instance_name" {
  description = "The name of the Label Studio instance"
  value       = google_compute_instance.label_studio.name
}

output "instance_external_ip" {
  description = "The external IP address of the Label Studio instance"
  value       = var.enable_external_ip ? google_compute_instance.label_studio.network_interface[0].access_config[0].nat_ip : null
}

output "instance_internal_ip" {
  description = "The internal IP address of the Label Studio instance"
  value       = google_compute_instance.label_studio.network_interface[0].network_ip
}

output "static_ip_address" {
  description = "The static IP address assigned to Label Studio (if enabled)"
  value       = var.enable_static_ip ? google_compute_address.label_studio_ip[0].address : null
}

output "label_studio_url" {
  description = "The URL to access Label Studio web interface"
  value       = var.enable_external_ip ? "http://${google_compute_instance.label_studio.network_interface[0].access_config[0].nat_ip}:8080" : "http://${google_compute_instance.label_studio.network_interface[0].network_ip}:8080"
}

output "service_account_email" {
  description = "The email of the service account used by Label Studio"
  value       = google_service_account.label_studio_sa.email
}

output "data_bucket_name" {
  description = "The name of the GCS bucket for Label Studio data"
  value       = google_storage_bucket.label_studio_data.name
}

output "vpc_name" {
  description = "The name of the VPC created for Label Studio"
  value       = google_compute_network.label_studio_vpc.name
}

output "subnet_name" {
  description = "The name of the subnet created for Label Studio"
  value       = google_compute_subnetwork.label_studio_subnet.name
}

output "firewall_rule_name" {
  description = "The name of the firewall rule for Label Studio"
  value       = google_compute_firewall.label_studio_web.name
}

output "ssh_command" {
  description = "SSH command to connect to the Label Studio instance"
  value       = "gcloud compute ssh ${var.ssh_user}@${google_compute_instance.label_studio.name} --zone=${var.zone}"
}

output "admin_credentials" {
  description = "Label Studio admin credentials"
  value = {
    username = var.admin_user
    password = var.admin_password
  }
  sensitive = true
} 