/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- east_west_tgw_spoke_vpcs/cloud_wan_policy.tf ---

# We get the list of AWS Region codes from var.aws_regions
locals {
  # We get the list of AWS Region codes from var.aws_regions
  regions = keys({ for k, v in var.aws_regions : k => v })

  # Information about the CIDR blocks and Inspection VPC attachments of each AWS Region
  region_information = {
    ireland = {
      cidr_blocks               = values({ for k, v in var.ireland_spoke_vpcs : k => v.cidr_block })
      inspection_vpc_attachment = module.ireland_inspection_vpc.core_network_attachment.id
    }
    nvirginia = {
      cidr_blocks               = values({ for k, v in var.nvirginia_spoke_vpcs : k => v.cidr_block })
      inspection_vpc_attachment = module.nvirginia_inspection_vpc.core_network_attachment.id
    }
    sydney = {
      cidr_blocks               = values({ for k, v in var.sydney_spoke_vpcs : k => v.cidr_block })
      inspection_vpc_attachment = module.sydney_inspection_vpc.core_network_attachment.id
    }
  }

  # We create a list of maps with the following format:
  # - inspection --> inspection segment to create the static routes
  # - destination --> destination AWS Region, to add the destination CIDRs + Inspection VPC of that Region
  region_combination = flatten(
    [for region1 in local.regions :
      [for region2 in local.regions :
        {
          inspection  = region1
          destination = region2
        }
        if region1 != region2
      ]
    ]
  )
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

  # Pre-Inspection segment
  segments {
    name                          = "preinspection"
    require_attachment_acceptance = false
    isolate_attachments           = var.segment_configuration == "default" ? false : true
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

  # Static routes from dev and prod segments to Inspection VPCs
  segment_actions {
    action                  = "create-route"
    segment                 = "preinspection"
    destination_cidr_blocks = ["0.0.0.0/0"]
    destinations            = values({ for k, v in local.region_information : k => v.inspection_vpc_attachment })
  }

  # Create of static routes - per AWS Region, we need to point those VPCs CIDRs to pass through the local Inspection VPC in the other inspection segments
  # For example, N. Virginia CIDRs to Inspection VPC in N.Virginia --> inspectionireland & inspectionsydney
  dynamic "segment_actions" {
    for_each = local.region_combination
    iterator = combination

    content {
      action                  = "create-route"
      segment                 = "postinspection${combination.value.inspection}"
      destination_cidr_blocks = local.region_information[combination.value.destination].cidr_blocks
      destinations            = [local.region_information[combination.value.destination].inspection_vpc_attachment]
    }
  }
}