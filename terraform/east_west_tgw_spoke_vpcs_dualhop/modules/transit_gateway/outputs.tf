/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- east_west_tgw_spoke_vpcs_dualhop/modules/transit_gateway/outputs.tf ---

output "transit_gateway_id" {
  description = "Transit Gateway ID."
  value       = aws_ec2_transit_gateway.transit_gateway.id
}