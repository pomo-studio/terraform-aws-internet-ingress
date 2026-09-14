# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-09-13

### Added

- The `internet-ingress` blueprint: one VPC origin per deployment, a CloudFront
  distribution with a deployment-aware cache policy, and the edge router wired
  into it. It composes the three ingress components into one root module.
