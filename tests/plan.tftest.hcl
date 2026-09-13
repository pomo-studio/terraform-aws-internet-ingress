# Offline plan tests for terraform-aws-internet-ingress.
#
# mock_provider keeps these running with no AWS credentials, so they gate every
# pull request. They pin the composition: two private origins, the router's
# associations wired into the distribution, and the rollout parameter. The live
# acceptance workflow proves the same stack on AWS.

mock_provider "aws" {
  mock_resource "aws_cloudfront_vpc_origin" {
    defaults = {
      id  = "E2MOCKORIGIN"
      arn = "arn:aws:cloudfront::123456789012:vpc-origin/E2MOCKORIGIN"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/acceptance-edge-router-sync"
    }
  }

  mock_resource "aws_ssm_parameter" {
    defaults = {
      arn = "arn:aws:ssm:us-east-1:123456789012:parameter/acceptance/rollout"
    }
  }

  mock_resource "aws_cloudfront_key_value_store" {
    defaults = {
      arn = "arn:aws:cloudfront::123456789012:key-value-store/acceptance"
    }
  }

  mock_resource "aws_cloudfront_function" {
    defaults = {
      arn = "arn:aws:cloudfront::123456789012:function/acceptance"
    }
  }

  mock_resource "aws_cloudfront_distribution" {
    defaults = {
      id             = "E2MOCKDISTRIBUTION"
      arn            = "arn:aws:cloudfront::123456789012:distribution/E2MOCKDISTRIBUTION"
      domain_name    = "d111111abcdef8.cloudfront.net"
      hosted_zone_id = "Z2FDTNDATAQYW2"
      status         = "Deployed"
    }
  }

  mock_resource "aws_lambda_function" {
    defaults = {
      arn = "arn:aws:lambda:us-east-1:123456789012:function:acceptance-edge-router-sync"
    }
  }

  mock_resource "aws_cloudwatch_event_rule" {
    defaults = {
      arn = "arn:aws:events:us-east-1:123456789012:rule/acceptance-edge-router-sync"
    }
  }
}

variables {
  name           = "acceptance"
  enable_logging = false

  deployments = {
    blue = {
      origin_arn  = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/blue/50dc6c495c0c9188"
      domain_name = "blue.internal.example.com"
    }
    green = {
      origin_arn  = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/green/50dc6c495c0c9188"
      domain_name = "green.internal.example.com"
    }
  }

  routing = {
    active = "blue"
    weight = 0
  }
}

run "composes_the_ingress" {
  command = apply

  assert {
    condition     = length(module.edge_router.function_associations) == 2
    error_message = "The router should provide both function associations."
  }

  assert {
    condition     = module.frontdoor.distribution_id == "E2MOCKDISTRIBUTION"
    error_message = "The blueprint should expose the distribution the frontdoor created."
  }

  assert {
    condition     = module.edge_router.parameter_name == "/acceptance/rollout"
    error_message = "The blueprint should expose the rollout parameter."
  }
}
