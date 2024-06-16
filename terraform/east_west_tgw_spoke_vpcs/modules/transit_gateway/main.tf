/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- east_west_tgw_spoke_vpcs/modules/transit_gateway/main.tf ---

data "aws_region" "current" {}

# ---------- TRANSIT GATEWAY RESOURCES ----------
# Transit Gateway
resource "aws_ec2_transit_gateway" "transit_gateway" {
  amazon_side_asn                 = var.tgw_asn
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  description                     = "Transit Gateway - ${data.aws_region.current.name}"

  tags = {
    Name = "tgw-${data.aws_region.current.name}-${var.identifier}"
  }
}

# Transit Gateway route tables
locals {
  route_tables = ["production", "prod_routes", "development"]
}

resource "aws_ec2_transit_gateway_route_table" "tgw_route_table" {
  for_each = { for rt in local.route_tables : rt => "rt" }

  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id

  tags = {
    Name = "${each.key}-rt-${var.identifier}"
  }
}

# Transit Gateway Route Table Associations
resource "aws_ec2_transit_gateway_route_table_association" "tgw_association" {
  for_each = var.vpc_information

  transit_gateway_attachment_id  = each.value.transit_gateway_attachment_id
  transit_gateway_route_table_id = each.value.segment == "production" ? aws_ec2_transit_gateway_route_table.tgw_route_table["production"].id : aws_ec2_transit_gateway_route_table.tgw_route_table["development"].id
}

# Transit Gateway Propagations
resource "aws_ec2_transit_gateway_route_table_propagation" "tgw_propagation" {
  for_each = var.vpc_information

  transit_gateway_attachment_id  = each.value.transit_gateway_attachment_id
  transit_gateway_route_table_id = each.value.segment == "production" ? aws_ec2_transit_gateway_route_table.tgw_route_table["prod_routes"].id : aws_ec2_transit_gateway_route_table.tgw_route_table["development"].id
}

# ---------- CLOUD WAN PEERING ----------
# Peering
resource "aws_networkmanager_transit_gateway_peering" "tgw_cwan_peering" {
  core_network_id     = var.core_network_id
  transit_gateway_arn = aws_ec2_transit_gateway.transit_gateway.arn

  tags = {
    Name = "peering-${data.aws_region.current.name}"
  }
}

# Transit Gateway Policy Table
resource "aws_ec2_transit_gateway_policy_table" "tgw_policy_table" {
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id

  tags = {
    Name = "Transit Gateway Policy Table - ${data.aws_region.current.name}"
  }
}

resource "aws_ec2_transit_gateway_policy_table_association" "tgw_policy_table_assoc" {
  transit_gateway_attachment_id   = aws_networkmanager_transit_gateway_peering.tgw_cwan_peering.transit_gateway_peering_attachment_id
  transit_gateway_policy_table_id = aws_ec2_transit_gateway_policy_table.tgw_policy_table.id
}

# Transit Gateway Route Table Attachments
resource "aws_networkmanager_transit_gateway_route_table_attachment" "rt_attachment" {
  for_each = aws_ec2_transit_gateway_route_table.tgw_route_table

  peering_id                      = aws_networkmanager_transit_gateway_peering.tgw_cwan_peering.id
  transit_gateway_route_table_arn = each.value.arn

  tags = {
    Name   = "TGW Route Table - ${each.key} - ${data.aws_region.current.name}"
    domain = each.key == "development" ? "development" : "production"
  }
}