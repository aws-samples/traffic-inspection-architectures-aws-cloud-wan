/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- east_west_tgw_spoke_vpcs/modules/transit_gateway/variables.tf ---

variable "identifier" {
  type        = string
  description = "Project identifier."
}

variable "tgw_asn" {
  type        = number
  description = "Transit Gateway ASN number."
}

variable "vpc_information" {
  type        = any
  description = "VPC information."
}

variable "core_network_id" {
  type        = string
  description = "Core Network ID."
}