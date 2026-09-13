output "application_url" {
  description = "Public URL of the application"
  value       = length(var.aliases) > 0 ? "https://${var.aliases[0]}" : "https://${module.frontdoor.domain_name}"
}

output "distribution_id" {
  description = "ID of the CloudFront distribution that fronts the application"
  value       = module.frontdoor.distribution_id
}

output "domain_name" {
  description = "CloudFront-assigned domain name"
  value       = module.frontdoor.domain_name
}

output "parameter_name" {
  description = "Parameter Store entry that holds the rollout state"
  value       = module.edge_router.parameter_name
}

output "deployment_header" {
  description = "Request header the router stamps with the chosen deployment"
  value       = module.edge_router.deployment_header
}

output "viewer_request_function_arn" {
  description = "ARN of the viewer-request function that selects the origin"
  value       = module.edge_router.viewer_request_function_arn
}
