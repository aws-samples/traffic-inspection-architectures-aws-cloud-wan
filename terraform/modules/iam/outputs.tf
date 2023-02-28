/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- module/iam/outputs.tf ---

output "ec2_iam_instance_profile" {
  description = "EC2 IAM Instance Profile."
  value       = aws_iam_instance_profile.ec2_instance_profile.id
}