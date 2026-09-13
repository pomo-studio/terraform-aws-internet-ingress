output "distribution_id" {
  description = "ID of the CloudFront distribution that fronts the application"
  value       = null
}

output "application_url" {
  description = "Public URL of the application"
  value       = null
}

output "domain_name" {
  description = "CloudFront-assigned domain name"
  value       = null
}

output "parameter_name" {
  description = "Parameter Store entry that holds the rollout state"
  value       = null
}
