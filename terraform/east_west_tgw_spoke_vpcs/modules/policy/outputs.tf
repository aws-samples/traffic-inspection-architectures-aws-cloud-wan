/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- east_west_tgw_spoke_vpcs/modules/policy/outputs.tf ---

output "policy_arn" {
  description = "AWS Network Firewall policy ARN."
  value       = aws_networkfirewall_firewall_policy.anfw_policy.arn
}