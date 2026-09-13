terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "name" {
  description = "Prefix for the acceptance resources"
  type        = string
  default     = "acceptance"
}

variable "region" {
  description = "AWS region for the acceptance run"
  type        = string
  default     = "us-east-1"
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  prefix = substr(var.name, 0, 20)

  tags = {
    ManagedBy   = "module-acceptance"
    AutoDestroy = "true"
  }
}

resource "aws_vpc" "this" {
  cidr_block           = "10.44.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = local.tags
}

resource "aws_subnet" "this" {
  count = 2

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = local.tags
}

resource "aws_security_group" "alb" {
  name_prefix = "${local.prefix}-alb-"
  description = "Acceptance load balancer ingress"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTP from inside the VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "blue" {
  name               = "${local.prefix}-blue"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.this[*].id

  tags = local.tags
}

resource "aws_lb_listener" "blue" {
  load_balancer_arn = aws_lb.blue.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "blue"
      status_code  = "200"
    }
  }
}

resource "aws_lb" "green" {
  name               = "${local.prefix}-green"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.this[*].id

  tags = local.tags
}

resource "aws_lb_listener" "green" {
  load_balancer_arn = aws_lb.green.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "green"
      status_code  = "200"
    }
  }
}

module "ingress" {
  source = "../../"

  name    = local.prefix
  routing = { active = "blue", weight = 0 }

  origin_protocol_policy = "http-only"
  enable_logging         = false

  deployments = {
    blue = {
      origin_arn  = aws_lb.blue.arn
      domain_name = aws_lb.blue.dns_name
    }
    green = {
      origin_arn  = aws_lb.green.arn
      domain_name = aws_lb.green.dns_name
    }
  }

  tags = local.tags
}

output "application_url" {
  description = "Public URL of the application"
  value       = module.ingress.application_url
}

output "domain_name" {
  description = "CloudFront domain name of the distribution"
  value       = module.ingress.domain_name
}

output "parameter_name" {
  description = "Parameter Store entry that holds the rollout state"
  value       = module.ingress.parameter_name
}
