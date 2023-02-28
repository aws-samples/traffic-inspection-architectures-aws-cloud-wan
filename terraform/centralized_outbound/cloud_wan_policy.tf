/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- centralized_outbound/cloud_wan_policy.tf ---

locals {
  # List of AWS Regions (from var.aws_regions)
  regions = values({ for k, v in var.aws_regions : k => v })
  # List of routing_domains in all AWS Regions
  routing_domains = distinct(concat(
    values({ for k, v in var.ireland_spoke_vpcs : k => v.segment }),
    values({ for k, v in var.nvirginia_spoke_vpcs : k => v.segment }),
    values({ for k, v in var.sydney_spoke_vpcs : k => v.segment })
  ))

  # Inspection VPC attachments in each AWS Region
  inspection_vpc_attachment = {
    ireland   = module.ireland_inspection_vpc.core_network_attachment.id
    nvirginia = module.nvirginia_inspection_vpc.core_network_attachment.id
    sydney    = module.sydney_inspection_vpc.core_network_attachment.id
  }
}

# AWS Cloud WAN Core Network Policy - Single Segment
data "aws_networkmanager_core_network_policy_document" "core_network_policy" {
  core_network_configuration {
    vpn_ecmp_support = false
    asn_ranges       = ["64520-65525"]

    dynamic "edge_locations" {
      for_each = local.regions
      iterator = region

      content {
        location = region.value
      }
    }
  }

  # We generate one segment per routing domain
  dynamic "segments" {
    for_each = local.routing_domains
    iterator = domain

    content {
      name                          = domain.value
      require_attachment_acceptance = false
      isolate_attachments           = false
    }
  }

  # One segment for all the Inspection VPCs
  segments {
    name                          = "security"
    require_attachment_acceptance = false
    isolate_attachments           = false
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

  # Sharing prod and dev routes to all the inspection segments
  dynamic "segment_actions" {
    for_each = local.routing_domains
    iterator = domain

    content {
      action     = "share"
      mode       = "attachment-route"
      segment    = domain.value
      share_with = ["security"]
    }
  }

  # Static routes from dev and prod segments to Inspection VPCs
  # dynamic "segment_actions" {
  #   for_each = local.routing_domains
  #   iterator = domain

  #   content {
  #     action                  = "create-route"
  #     segment                 = domain.value
  #     destination_cidr_blocks = ["0.0.0.0/0"]
  #     destinations            = values({ for k, v in local.inspection_vpc_attachment : k => v })
  #   }
  # }
}