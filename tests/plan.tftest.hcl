# Offline plan tests for terraform-aws-internet-ingress.
#
# The blueprint is still being implemented, so these tests pin the input
# contract. They run with no AWS credentials; the live acceptance workflow is
# added once the component modules it composes are released.

variables {
  name = "acceptance"

  deployments = {
    blue = {
      origin_arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/blue/50dc6c495c0c9188"
    }
    green = {
      origin_arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/green/50dc6c495c0c9188"
    }
  }
}

run "plans_with_two_deployments" {
  command = plan
}

run "plans_with_routing_state" {
  command = plan

  variables {
    routing = {
      active = "blue"
      weight = 10
    }
  }
}
