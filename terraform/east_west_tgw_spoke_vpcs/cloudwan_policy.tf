/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- east_west_tgw_spoke_vpcs/cloudwan_policy.tf ---

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
}

data "aws_networkmanager_core_network_policy_document" "policy" {
  core_network_configuration {
    vpn_ecmp_support = false
    asn_ranges       = ["64520-65525"]

    dynamic "edge_locations" {
      for_each = var.aws_regions
      iterator = region

      content {
        location = region.value.code
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

  dynamic "segment_actions" {
    for_each = local.segments
    iterator = segment

    content {
      action  = "send-to"
      segment = segment.key

      via {
        network_function_groups = ["inspectionVpcs"]
      }
    }
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
    }
  }

  segment_actions {
    action  = "send-via"
    segment = "production"
    mode    = "single-hop"

    via {
      network_function_groups = ["inspectionVpcs"]
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
        location = region.value.code
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