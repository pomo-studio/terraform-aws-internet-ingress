# terraform-aws-internet-ingress

[![Terraform Validation](https://github.com/pomo-studio/terraform-aws-internet-ingress/actions/workflows/terraform.yml/badge.svg)](https://github.com/pomo-studio/terraform-aws-internet-ingress/actions/workflows/terraform.yml)
[![Terraform Registry](https://img.shields.io/badge/terraform-registry-844FBA?logo=terraform)](https://registry.terraform.io/modules/pomo-studio/internet-ingress/aws)

[Changelog](CHANGELOG.md)

A reusable customer-facing front door: CloudFront terminates traffic, reaches private backends through VPC origins, and shifts between blue and green at the edge. The blueprint composes the ingress components into one root module.

## When to use it

Reach for this blueprint when you have an application behind a private load balancer and you want a front door with a certificate, optional WAF, logging, and edge blue/green, without building the same CloudFront stack each time.

The blueprint does not create the load balancer or the backend, and authentication is out of scope. You pass the existing private origin ARNs; the module owns the ingress. The VPC behind each origin needs an internet gateway, which CloudFront requires for VPC origins.

## Quickstart

```hcl
module "orders_ingress" {
  source  = "pomo-studio/internet-ingress/aws"
  version = "~> 0.1"

  name    = "orders"
  aliases = ["orders.example.com"]

  acm_certificate_arn = aws_acm_certificate.orders.arn

  deployments = {
    blue = {
      origin_arn  = aws_lb.orders_blue.arn
      domain_name = aws_lb.orders_blue.dns_name
    }
    green = {
      origin_arn  = aws_lb.orders_green.arn
      domain_name = aws_lb.orders_green.dns_name
    }
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

- **Existing origins are inputs.** The blueprint takes origin ARNs and their domains, so the load balancer and the application stay with the team that runs them.
- **Rollout state is data.** Active colour, weight, and pin cookie live in Parameter Store and reach the edge through the router, so promotion is a parameter update rather than a plan.
- **CloudFront Functions, not Lambda@Edge.** VPC origins reject Lambda@Edge origin triggers, so the router selects the origin with a CloudFront Function on the JavaScript runtime 2.0, using `selectRequestOriginById`.
- **The cache key carries the deployment.** The router stamps a deployment header and the distribution keys its cache on it, so blue and green never serve each other cached responses.
- **Edge blue/green is near-instant, not atomic.** A weight change propagates with the store; it is not a transactional switch.

## What it creates

| Component | Module |
|-----------|--------|
| VPC origin per deployment | `pomo-studio/cloudfront-vpc-origin/aws` |
| Distribution, WAF, logging, policies | `pomo-studio/cloudfront-frontdoor/aws` |
| Edge routing function, store, and sync | `pomo-studio/cloudfront-edge-router/aws` |

## Examples

- [Basic](examples/basic/): two private origins behind one distribution.
- [Live](examples/live/): a self-contained VPC and two internal load balancers, used by the live acceptance workflow.

## Reference

<details>
<summary>Reference</summary>

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | >= 2.4 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0, < 7.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_edge_router"></a> [edge\_router](#module\_edge\_router) | git::https://github.com/pomo-studio/terraform-aws-cloudfront-edge-router.git | v0.1.0 |
| <a name="module_frontdoor"></a> [frontdoor](#module\_frontdoor) | git::https://github.com/pomo-studio/terraform-aws-cloudfront-frontdoor.git | v0.1.0 |
| <a name="module_vpc_origin"></a> [vpc\_origin](#module\_vpc\_origin) | git::https://github.com/pomo-studio/terraform-aws-cloudfront-vpc-origin.git | v0.1.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acm_certificate_arn"></a> [acm\_certificate\_arn](#input\_acm\_certificate\_arn) | ARN of the ACM certificate in us-east-1 that covers the aliases. Required when aliases are set. | `string` | `null` | no |
| <a name="input_aliases"></a> [aliases](#input\_aliases) | Alternate domain names (CNAMEs) for the distribution | `list(string)` | `[]` | no |
| <a name="input_default_root_object"></a> [default\_root\_object](#input\_default\_root\_object) | Object CloudFront returns for requests to the root URL | `string` | `null` | no |
| <a name="input_deployments"></a> [deployments](#input\_deployments) | Deployments keyed by name. Each names an existing private origin, by ARN and domain, and becomes an origin on the distribution. | <pre>map(object({<br/>    origin_arn  = string<br/>    domain_name = string<br/>  }))</pre> | n/a | yes |
| <a name="input_enable_logging"></a> [enable\_logging](#input\_enable\_logging) | Write access logs to logging\_bucket | `bool` | `true` | no |
| <a name="input_enable_waf"></a> [enable\_waf](#input\_enable\_waf) | Associate a web ACL with the distribution | `bool` | `false` | no |
| <a name="input_logging_bucket"></a> [logging\_bucket](#input\_logging\_bucket) | S3 bucket for standard access logs. Required when enable\_logging is true. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the ingress and its supporting resources | `string` | n/a | yes |
| <a name="input_origin_protocol_policy"></a> [origin\_protocol\_policy](#input\_origin\_protocol\_policy) | Protocol the distribution uses to reach the origins (http-only, match-viewer, or https-only) | `string` | `"https-only"` | no |
| <a name="input_routing"></a> [routing](#input\_routing) | Rollout state. active is the deployment that receives traffic, weight is the percentage sent to the other deployment, and pin\_cookie keeps a viewer on one deployment. | <pre>object({<br/>    active     = string<br/>    weight     = optional(number, 0)<br/>    pin_cookie = optional(string)<br/>  })</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all resources | `map(string)` | `{}` | no |
| <a name="input_web_acl_id"></a> [web\_acl\_id](#input\_web\_acl\_id) | ARN of the web ACL to associate when enable\_waf is true | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_application_url"></a> [application\_url](#output\_application\_url) | Public URL of the application |
| <a name="output_deployment_header"></a> [deployment\_header](#output\_deployment\_header) | Request header the router stamps with the chosen deployment |
| <a name="output_distribution_id"></a> [distribution\_id](#output\_distribution\_id) | ID of the CloudFront distribution that fronts the application |
| <a name="output_domain_name"></a> [domain\_name](#output\_domain\_name) | CloudFront-assigned domain name |
| <a name="output_parameter_name"></a> [parameter\_name](#output\_parameter\_name) | Parameter Store entry that holds the rollout state |
| <a name="output_viewer_request_function_arn"></a> [viewer\_request\_function\_arn](#output\_viewer\_request\_function\_arn) | ARN of the viewer-request function that selects the origin |
<!-- END_TF_DOCS -->

</details>

## Support and license

Part of the [pomo-studio](https://github.com/pomo-studio) Terraform modules, run in production by [postmodern.](https://pomo.studio). Regenerate the reference with `terraform-docs` v0.20.0 (`terraform-docs .`); CI fails on drift.

See the [contribution guide](https://github.com/pomo-studio/.github/blob/main/CONTRIBUTING.md) and [security policy](https://github.com/pomo-studio/.github/blob/main/SECURITY.md).

MIT licensed. See [LICENSE](LICENSE).
