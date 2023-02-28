/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- east_west_tgw/modules/inspection/variables.tf ---

variable "identifier" {
  description = "Project identifier."
  type        = string
}

variable "vpc" {
  description = "Ingress/Inspection VPC information."
  type        = any
}

variable "number_azs" {
  description = "Number of AZs to create the Network Firewall and Load Balancer resources."
  type        = number
}