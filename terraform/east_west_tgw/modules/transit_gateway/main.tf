/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- east_west_tgw/modules/transit_gateway/main.tf ---

# ---------- TRANSIT GATEWAY RESOURCES ----------
# Transit Gateway
resource "aws_ec2_transit_gateway" "transit_gateway" {
  amazon_side_asn                 = var.tgw_asn
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  description                     = "Transit Gateway - ${var.aws_region}"

  tags = {
    Name = "tgw-${var.aws_region}-${var.identifier}"
  }
}

# Transit Gateway route tables
resource "aws_ec2_transit_gateway_route_table" "pre_inspection" {
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id

  tags = {
    Name = "Pre-Inspection-${var.identifier}"
  }
}

resource "aws_ec2_transit_gateway_route_table" "post_inspection" {
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id

  tags = {
    Name = "Post-Inspection-${var.identifier}"
  }
}

resource "aws_ec2_transit_gateway_route_table" "cross_region" {
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id

  tags = {
    Name = "Cross-Region-${var.identifier}"
  }
}

# Transit Gateway Route Table Associations
resource "aws_ec2_transit_gateway_route_table_association" "spoke_association" {
  for_each = var.spoke_vpc_tgw_attachment_ids

  transit_gateway_attachment_id  = each.value
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.pre_inspection.id
}

resource "aws_ec2_transit_gateway_route_table_association" "inspection_association" {
  transit_gateway_attachment_id  = var.inspection_vpc_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.post_inspection.id
}

# Transit Gateway Propagation - Spokes to Post-Inspection Route Table
resource "aws_ec2_transit_gateway_route_table_propagation" "spokes_to_post_inspection" {
  for_each = var.spoke_vpc_tgw_attachment_ids

  transit_gateway_attachment_id  = each.value
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.post_inspection.id
}

# Static Route - 0.0.0.0/0 to Inspection VPC
resource "aws_ec2_transit_gateway_route" "default_to_inspection" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = var.inspection_vpc_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.pre_inspection.id
}

# Prefix List Reference - VPC CIDRs in Region to Inspection VPC
resource "aws_ec2_transit_gateway_prefix_list_reference" "prefix_list_to_inspection" {
  prefix_list_id                 = var.spokes_prefix_list
  transit_gateway_attachment_id  = var.inspection_vpc_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.cross_region.id
}

# ---------- CLOUD WAN PEERING ----------
# Peering
resource "aws_networkmanager_transit_gateway_peering" "tgw_cwan_peering" {
  core_network_id     = var.core_network_id
  transit_gateway_arn = aws_ec2_transit_gateway.transit_gateway.arn

  tags = {
    Name = "peering-${var.aws_region}"
  }
}

# Transit Gateway Policy Table
resource "aws_ec2_transit_gateway_policy_table" "tgw_policy_table" {
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id

  tags = {
    Name = "Transit Gateway Policy Table - ${var.aws_region}"
  }
}

resource "aws_ec2_transit_gateway_policy_table_association" "tgw_policy_table_assoc" {
  transit_gateway_attachment_id   = aws_networkmanager_transit_gateway_peering.tgw_cwan_peering.transit_gateway_peering_attachment_id
  transit_gateway_policy_table_id = aws_ec2_transit_gateway_policy_table.tgw_policy_table.id
}

# Transit Gateway Route Table Attachment - Post-Inspection RT
resource "aws_networkmanager_transit_gateway_route_table_attachment" "post_inspection_rt_attachment" {
  peering_id                      = aws_networkmanager_transit_gateway_peering.tgw_cwan_peering.id
  transit_gateway_route_table_arn = aws_ec2_transit_gateway_route_table.post_inspection.arn

  tags = {
    Name   = "TGW Route Table - Post-Inspection ${var.aws_region}"
    domain = "postinspection${var.aws_region}"
  }
}

# Transit Gateway Route Table Attachment - Cross-Region RT
resource "aws_networkmanager_transit_gateway_route_table_attachment" "cross_region_rt_attachment" {
  peering_id                      = aws_networkmanager_transit_gateway_peering.tgw_cwan_peering.id
  transit_gateway_route_table_arn = aws_ec2_transit_gateway_route_table.cross_region.arn

  tags = {
    Name   = "TGW Route Table - Cross-Region ${var.aws_region}"
    domain = "crossregion${var.aws_region}"
  }
}