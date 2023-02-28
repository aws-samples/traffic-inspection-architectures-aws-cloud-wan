/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- module/compute/outputs.tf ---

output "instances_created" {
  value       = aws_instance.ec2_instance
  description = "List of instances created."
}