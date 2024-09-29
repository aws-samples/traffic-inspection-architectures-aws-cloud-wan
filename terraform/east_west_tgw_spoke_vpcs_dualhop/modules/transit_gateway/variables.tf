/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- east_west_tgw_spoke_vpcs_dualhop/modules/transit_gateway/variables.tf ---

variable "identifier" {
  type        = string
  description = "Project identifier."
}

variable "tgw_asn" {
  type        = number
  description = "Transit Gateway ASN number."
}

variable "spoke_vpc_information" {
  type        = any
  description = "Spoke VPCs information."
}

variable "inspection_vpc_tgw_attachment" {
  type        = string
  description = "Inspection VPC attachment ID."
}

variable "core_network_id" {
  type        = string
  description = "Core Network ID."
}

