/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- east_west_tgw/modules/transit_gateway/variables.tf ---

variable "identifier" {
  type        = string
  description = "Project identifier."
}

variable "aws_region" {
  type        = string
  description = "AWS Region to create the resources."
}

variable "tgw_asn" {
  type        = number
  description = "Transit Gateway ASN number."
}

variable "spokes_prefix_list" {
  type        = string
  description = "Prefix List with the Spoke VPC CIDRs."
}

variable "spoke_vpc_tgw_attachment_ids" {
  type        = map(string)
  description = "Transit Gateway Attachment IDs - Spoke VPC."
}

variable "inspection_vpc_attachment_id" {
  type        = string
  description = "Transit Gateway Attachment ID - Inspection VPC."
}

variable "core_network_id" {
  type        = string
  description = "Core Network ID."
}