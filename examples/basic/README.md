# Internet ingress basics

Wire a VPC origin, edge router, and frontdoor into one ingress stack.

## What it creates

- One VPC origin per deployment, blue and green.
- An edge router with the rollout state, key value store, CloudFront Functions, and sync Lambda.
- A frontdoor distribution for `orders.example.com` with the router functions attached.

## Before you start

- Provider `hashicorp/aws` with credentials for the target account.
- The example uses a local source, `../../`. The module itself pulls `vpc-origin`, `edge-router`, and `frontdoor` from sibling git repos at `?ref=v0.1.0`.
- The ACM certificate, logging bucket, and load balancer ARNs must already exist. The values here are placeholders. Replace them with real ones.

## Run it

```bash
terraform init
terraform plan
terraform apply
```

## Clean up

```bash
terraform destroy
```
