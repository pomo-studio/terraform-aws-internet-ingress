# The blueprint composes three components. This root module will:
#
#   - create one cloudfront-vpc-origin per deployment from the origin ARNs in
#     var.deployments
#   - create a cloudfront-frontdoor distribution over those origins, with the
#     certificate, optional WAF, and logging
#   - create a cloudfront-edge-router that reads rollout state from Parameter
#     Store and shifts requests between deployments
#
# The component modules are referenced by registry source once they are
# released. Until then this module is a placeholder so the blueprint has a home.
