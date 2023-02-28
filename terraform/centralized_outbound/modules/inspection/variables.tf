/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- centralized_outbound/modules/inspection/variables.tf ---

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

variable "network_cidr_blocks" {
  description = "List of CIDR blocks (network's supernet) to add in VPC routes."
  type        = list(string)
}