/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- module/endpoints/main.tf ---

variable "identifier" {
  description = "Project identifier."
  type        = string
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC where the VPC endpoints are created."
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC to create the endpoint(s)."
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block."
}

variable "vpc_subnets" {
  type        = list(string)
  description = "List of the subnets to place the endpoint(s)."
}

variable "aws_region" {
  type        = string
  description = "AWS Region to create the endpoints."
}