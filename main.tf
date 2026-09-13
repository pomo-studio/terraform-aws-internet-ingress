locals {
  active         = var.routing.active
  deployment_ids = toset(keys(var.deployments))
}

module "vpc_origin" {
  for_each = var.deployments
  source   = "git::https://github.com/pomo-studio/terraform-aws-cloudfront-vpc-origin.git?ref=main"

  name                   = "${var.name}-${each.key}"
  origin_arn             = each.value.origin_arn
  origin_protocol_policy = var.origin_protocol_policy
  tags                   = var.tags
}

module "edge_router" {
  source = "git::https://github.com/pomo-studio/terraform-aws-cloudfront-edge-router.git?ref=main"

  name              = var.name
  deployments       = local.deployment_ids
  active_deployment = local.active
  weight            = var.routing.weight
  pin_cookie        = var.routing.pin_cookie
  tags              = var.tags
}

module "frontdoor" {
  source = "git::https://github.com/pomo-studio/terraform-aws-cloudfront-frontdoor.git?ref=main"

  name                = var.name
  aliases             = var.aliases
  acm_certificate_arn = var.acm_certificate_arn
  default_root_object = var.default_root_object

  deployments = {
    for key, deployment in var.deployments : key => {
      vpc_origin_id = module.vpc_origin[key].id
      domain_name   = deployment.domain_name
    }
  }

  default_deployment    = local.active
  deployment_header     = module.edge_router.deployment_header
  function_associations = module.edge_router.function_associations

  enable_waf     = var.enable_waf
  web_acl_id     = var.web_acl_id
  enable_logging = var.enable_logging
  logging_bucket = var.logging_bucket

  tags = var.tags
}
