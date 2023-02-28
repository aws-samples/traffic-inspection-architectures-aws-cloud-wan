/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- east_west_tgw/cloud_wan_policy.tf ---

# We get the list of AWS Region codes from var.aws_regions
locals {
  regions = keys({ for k, v in var.aws_regions : k => v })
}

# AWS Cloud WAN Core Network Policy
data "aws_networkmanager_core_network_policy_document" "core_network_policy" {
  core_network_configuration {
    vpn_ecmp_support = false
    asn_ranges       = ["64520-65525"]

    dynamic "edge_locations" {
      for_each = local.regions
      iterator = region

      content {
        location = var.aws_regions[region.value].code
      }
    }
  }

  # Post-Inspection segments (1 per AWS Region)
  dynamic "segments" {
    for_each = local.regions
    iterator = region

    content {
      name                          = "postinspection${region.value}"
      require_attachment_acceptance = false
      isolate_attachments           = false
    }
  }

  # Cross-Region segments (1 per AWS Region)
  dynamic "segments" {
    for_each = local.regions
    iterator = region

    content {
      name                          = "crossregion${region.value}"
      require_attachment_acceptance = false
      isolate_attachments           = false
    }
  }

  attachment_policies {
    rule_number     = 100
    condition_logic = "or"

    conditions {
      type = "tag-exists"
      key  = "domain"
    }

    action {
      association_method = "tag"
      tag_value_of_key   = "domain"
    }
  }

  # For each AWS Region, the cross-region segment shares to the post-inspection segment in the other AWS Regions
  dynamic "segment_actions" {
    for_each = local.regions
    iterator = region

    content {
      action     = "share"
      mode       = "attachment-route"
      segment    = "crossregion${region.value}"
      share_with = [for r in local.regions : "postinspection${r}" if r != region.value]
    }
  }
}