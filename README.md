# terraform-aws-internet-ingress

[![Terraform Validation](https://github.com/pomo-studio/terraform-aws-internet-ingress/actions/workflows/terraform.yml/badge.svg)](https://github.com/pomo-studio/terraform-aws-internet-ingress/actions/workflows/terraform.yml)
[![Terraform Registry](https://img.shields.io/badge/terraform-registry-844FBA?logo=terraform)](https://registry.terraform.io/modules/pomo-studio/internet-ingress/aws)

[Changelog](CHANGELOG.md)

A reusable customer-facing front door: CloudFront terminates traffic, reaches private backends through VPC origins, and shifts between blue and green at the edge. The blueprint composes the ingress components into one root module.

> **Status:** design. The interface follows the [Internet Ingress](https://pomo.dev/blueprints) blueprint and is not yet released.

## When to use it

Reach for this blueprint when you have an application behind a private load balancer and you want a front door with a certificate, optional WAF, logging, and edge blue/green, without building the same CloudFront stack each time.

The blueprint does not create the load balancer or the backend, and authentication is out of scope. You pass the existing private origin ARNs; the module owns the ingress.

## Quickstart

```hcl
module "orders_ingress" {
  source  = "pomo-studio/internet-ingress/aws"
  version = "~> 0.1"

  name    = "orders"
  aliases = ["orders.example.com"]

  acm_certificate_arn = aws_acm_certificate.orders.arn

  deployments = {
    blue  = { origin_arn = aws_lb.orders_blue.arn }
    green = { origin_arn = aws_lb.orders_green.arn }
  }

  routing = {
    active = "blue"
    weight = 0
  }

  enable_waf     = true
  web_acl_id     = aws_wafv2_web_acl.orders.arn
  enable_logging = true
  logging_bucket = aws_s3_bucket.logs.bucket

  tags = { Environment = "production" }
}
```

## Design decisions

- **Existing origins are inputs.** The blueprint takes origin ARNs, so the load balancer and the application stay with the team that runs them.
- **Rollout state is data.** Active colour, weight, and pin cookie live in Parameter Store and are read at the edge, so promotion is a parameter update rather than a plan.
- **Single region by default.** DR is opt-in: `enable_dr` adds a failover origin per colour.
- **Edge blue/green is near-instant, not atomic.** Cache keys include the deployment colour; without that, a cached blue response can be served to a green request.

## What it creates

| Component | Module |
|-----------|--------|
| VPC origin per deployment | `pomo-studio/cloudfront-vpc-origin/aws` |
| Distribution, WAF, logging, policies | `pomo-studio/cloudfront-frontdoor/aws` |
| Edge routing function, store, and sync | `pomo-studio/cloudfront-edge-router/aws` |

## Reference

<details>
<summary>Reference</summary>

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0, < 7.0 |

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acm_certificate_arn"></a> [acm\_certificate\_arn](#input\_acm\_certificate\_arn) | ARN of the ACM certificate in us-east-1 that covers the aliases. Required when aliases are set. | `string` | `null` | no |
| <a name="input_aliases"></a> [aliases](#input\_aliases) | Alternate domain names (CNAMEs) for the distribution | `list(string)` | `[]` | no |
| <a name="input_deployments"></a> [deployments](#input\_deployments) | Deployment colours keyed by name, each with an existing private origin ARN | <pre>map(object({<br/>    origin_arn = string<br/>  }))</pre> | n/a | yes |
| <a name="input_enable_dr"></a> [enable\_dr](#input\_enable\_dr) | Add a failover origin per deployment for a second region | `bool` | `false` | no |
| <a name="input_enable_logging"></a> [enable\_logging](#input\_enable\_logging) | Write access logs to logging\_bucket | `bool` | `true` | no |
| <a name="input_enable_waf"></a> [enable\_waf](#input\_enable\_waf) | Associate a web ACL with the distribution | `bool` | `false` | no |
| <a name="input_logging_bucket"></a> [logging\_bucket](#input\_logging\_bucket) | S3 bucket for standard access logs. Required when enable\_logging is true. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the ingress and its supporting resources | `string` | n/a | yes |
| <a name="input_routing"></a> [routing](#input\_routing) | Rollout state. active is the deployment that receives traffic, weight is the percentage sent to the other deployment, and pin\_cookie keeps a viewer on a specific deployment. | <pre>object({<br/>    active     = string<br/>    weight     = optional(number, 0)<br/>    pin_cookie = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all resources | `map(string)` | `{}` | no |
| <a name="input_web_acl_id"></a> [web\_acl\_id](#input\_web\_acl\_id) | ARN of the web ACL to associate when enable\_waf is true | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_application_url"></a> [application\_url](#output\_application\_url) | Public URL of the application |
| <a name="output_distribution_id"></a> [distribution\_id](#output\_distribution\_id) | ID of the CloudFront distribution that fronts the application |
| <a name="output_domain_name"></a> [domain\_name](#output\_domain\_name) | CloudFront-assigned domain name |
| <a name="output_parameter_name"></a> [parameter\_name](#output\_parameter\_name) | Parameter Store entry that holds the rollout state |
<!-- END_TF_DOCS -->

</details>

## Support and license

Part of the [pomo-studio](https://github.com/pomo-studio) Terraform modules, run in production by [postmodern.](https://pomo.studio). Regenerate the reference with `terraform-docs` v0.20.0 (`terraform-docs .`); CI fails on drift.

See the [contribution guide](https://github.com/pomo-studio/.github/blob/main/CONTRIBUTING.md) and [security policy](https://github.com/pomo-studio/.github/blob/main/SECURITY.md).

MIT licensed. See [LICENSE](LICENSE).
