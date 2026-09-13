terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
  }
}

module "orders_ingress" {
  source = "../../"

  name    = "orders"
  aliases = ["orders.example.com"]

  acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/11111111-2222-3333-4444-555555555555"

  deployments = {
    blue = {
      origin_arn  = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/orders-blue/50dc6c495c0c9188"
      domain_name = "orders-blue.internal.example.com"
    }
    green = {
      origin_arn  = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/orders-green/50dc6c495c0c9188"
      domain_name = "orders-green.internal.example.com"
    }
  }

  routing = {
    active = "blue"
    weight = 0
  }

  enable_logging = true
  logging_bucket = "example-cloudfront-logs"

  tags = {
    Environment = "production"
  }
}
