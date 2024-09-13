/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- east_west_singlehop/cloudwan_policy.tf ---

locals {
  segments = {
    production = {
      require_attachment_acceptance = false
      isolate_attachments           = true
    }
    development = {
      require_attachment_acceptance = false
      isolate_attachments           = false
    }
  }

  edge_overrides = {
    nvirginia_ireland = {
      edge_sets     = [["us-east-1", "eu-west-1"]]
      edge_location = "us-east-1"
    }
    nvirginia_sydney = {
      edge_sets     = [["us-east-1", "ap-southeast-2"]]
      edge_location = "us-east-1"
    }
    nvirginia_london = {
      edge_sets     = [["us-east-1", "eu-west-2"]]
      edge_location = "us-east-1"
    }
    sydney_ireland = {
      edge_sets     = [["ap-southeast-2", "eu-west-1"]]
      edge_location = "eu-west-1"
    }
    sydney_london = {
      edge_sets     = [["ap-southeast-2", "eu-west-2"]]
      edge_location = "ap-southeast-2"
    }
    ireland_london = {
      edge_sets     = [["eu-west-2", "eu-west-1"]]
      edge_location = "eu-west-1"
    }
    london_default = {
      edge_sets     = [["eu-west-2"]]
      edge_location = "eu-west-1"
    }
  }
}

data "aws_networkmanager_core_network_policy_document" "policy" {
  core_network_configuration {
    vpn_ecmp_support = false
    asn_ranges       = ["64520-65525"]

    dynamic "edge_locations" {
      for_each = var.aws_regions
      iterator = region

      content {
        location = region.value
      }
    }
  }

  dynamic "segments" {
    for_each = local.segments
    iterator = segment

    content {
      name                          = segment.key
      require_attachment_acceptance = segment.value.require_attachment_acceptance
      isolate_attachments           = segment.value.isolate_attachments
    }
  }

  network_function_groups {
    name                          = "inspectionVpcs"
    require_attachment_acceptance = false
  }

  segment_actions {
    action  = "send-via"
    segment = "production"
    mode    = "single-hop"

    when_sent_to {
      segments = ["development"]
    }

    via {
      network_function_groups = ["inspectionVpcs"]

      dynamic "with_edge_override" {
        for_each = local.edge_overrides
        iterator = override

        content {
          edge_sets         = override.value.edge_sets
          use_edge_location = override.value.edge_location
        }
      }
    }
  }

  segment_actions {
    action  = "send-via"
    segment = "production"
    mode    = "single-hop"

    via {
      network_function_groups = ["inspectionVpcs"]

      dynamic "with_edge_override" {
        for_each = local.edge_overrides
        iterator = override

        content {
          edge_sets         = override.value.edge_sets
          use_edge_location = override.value.edge_location
        }
      }
    }
  }

  attachment_policies {
    rule_number     = 100
    condition_logic = "or"

    conditions {
      type     = "tag-value"
      operator = "equals"
      key      = "inspection"
      value    = "true"
    }
    action {
      add_to_network_function_group = "inspectionVpcs"
    }
  }

  attachment_policies {
    rule_number     = 200
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
}

data "aws_networkmanager_core_network_policy_document" "base_policy" {
  core_network_configuration {
    vpn_ecmp_support = false
    asn_ranges       = ["64520-65525"]

    dynamic "edge_locations" {
      for_each = var.aws_regions
      iterator = region

      content {
        location = region.value
      }
    }
  }

  dynamic "segments" {
    for_each = local.segments
    iterator = segment

    content {
      name                          = segment.key
      require_attachment_acceptance = segment.value.require_attachment_acceptance
      isolate_attachments           = segment.value.isolate_attachments
    }
  }

  network_function_groups {
    name                          = "inspectionVpcs"
    require_attachment_acceptance = false
  }

  attachment_policies {
    rule_number     = 100
    condition_logic = "or"

    conditions {
      type     = "tag-value"
      operator = "equals"
      key      = "inspection"
      value    = "true"
    }
    action {
      add_to_network_function_group = "inspectionVpcs"
    }
  }

  attachment_policies {
    rule_number     = 200
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
}