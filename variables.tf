variable "name" {
  description = "Name of the ingress and its supporting resources"
  type        = string
}

variable "aliases" {
  description = "Alternate domain names (CNAMEs) for the distribution"
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate in us-east-1 that covers the aliases. Required when aliases are set."
  type        = string
  default     = null
}

variable "default_root_object" {
  description = "Object CloudFront returns for requests to the root URL"
  type        = string
  default     = null
}

variable "deployments" {
  description = "Deployments keyed by name. Each names an existing private origin, by ARN and domain, and becomes an origin on the distribution."
  type = map(object({
    origin_arn  = string
    domain_name = string
  }))
}

variable "routing" {
  description = "Rollout state. active is the deployment that receives traffic, weight is the percentage sent to the other deployment, and pin_cookie keeps a viewer on one deployment."
  type = object({
    active     = string
    weight     = optional(number, 0)
    pin_cookie = optional(string)
  })
}

variable "origin_protocol_policy" {
  description = "Protocol the distribution uses to reach the origins (http-only, match-viewer, or https-only)"
  type        = string
  default     = "https-only"
}

variable "enable_waf" {
  description = "Associate a web ACL with the distribution"
  type        = bool
  default     = false
}

variable "web_acl_id" {
  description = "ARN of the web ACL to associate when enable_waf is true"
  type        = string
  default     = null
}

variable "enable_logging" {
  description = "Write access logs to logging_bucket"
  type        = bool
  default     = true
}

variable "logging_bucket" {
  description = "S3 bucket for standard access logs. Required when enable_logging is true."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
