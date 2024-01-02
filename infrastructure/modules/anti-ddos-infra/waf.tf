resource "aws_wafv2_ip_set" "whitelist" {

  lifecycle {
    ignore_changes = [
      # addresses
    ]
  }

  name               = "ip-whitelist-${var.project}"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = var.whitelist
}

resource "aws_wafv2_web_acl" "this" {
  name        = "myWebACL-${var.project}"
  description = "managed rules"
  scope       = "REGIONAL"

  default_action {
    allow {
    }
  }

  rule {
    name     = "ip-whitelist"
    priority = 0

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.whitelist.arn
        #arn = data.terraform_remote_state.global.outputs.whitelist
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "ip-whitelist"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "host-tracker"
    priority = 1

    action {
      allow {
      }
    }

    statement {
      byte_match_statement {
        positional_constraint = "EXACTLY"
        search_string         = "Mozilla/5.0 (compatible;HostTracker/2.0;+http://www.host-tracker.com/)"

        field_to_match {
          single_header {
            name = "user-agent"
          }
        }

        text_transformation {
          priority = 0
          type     = "NONE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "host-tracker"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "highrates"
    priority = 2

    action {
      block {
      }
    }

    statement {
      rate_based_statement {
        aggregate_key_type = "IP"
        limit              = 300
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "highrates"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesAmazonIpReputationList"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }



  rule {
    name     = "AWS-AWSManagedRulesAnonymousIpList"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesAnonymousIpList"
      sampled_requests_enabled   = true
    }
  }


  visibility_config {
    cloudwatch_metrics_enabled = true
    #metric_name                = "myWebACL"
    metric_name              = "myWebACL-${var.project}"
    sampled_requests_enabled = true
  }
}

resource "aws_wafv2_web_acl_association" "this" {
  count        = (var.under_attack == 1) ? 1 : 0
  resource_arn = aws_lb.public.arn
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}

output "under_attack" {
  value = var.under_attack
}
