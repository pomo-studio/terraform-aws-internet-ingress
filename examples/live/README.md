# Internet ingress live

Apply the ingress module against real AWS resources in an acceptance run.

## What it creates

- A VPC with DNS support and an internet gateway. CloudFront VPC origins require the gateway.
- Two subnets across available zones and a security group that allows HTTP inside the VPC.
- Two internal load balancers, blue and green, each with a fixed-response listener.
- The ingress module: one VPC origin per load balancer, the edge router, and a frontdoor distribution. Logging is off.

## Before you start

- Provider `hashicorp/aws`. Credentials must have permission to create VPC, ELB, CloudFront, Lambda, and SSM resources.
- The example uses a local source, `../../`. The module itself pulls its sibling modules from git at `?ref=v0.1.0`.
- Variables `name` and `region` are set here. The acceptance workflow applies and later destroys this example, so it creates its own prerequisites.

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
