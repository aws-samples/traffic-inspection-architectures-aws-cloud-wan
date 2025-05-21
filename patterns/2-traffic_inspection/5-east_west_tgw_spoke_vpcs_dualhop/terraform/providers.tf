/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- east_west_tgw_spoke_vpcs_dualhop/providers.tf ---

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.67.0"
    }
  }
}

# Provider definition for Ireland Region
provider "aws" {
  region = var.aws_regions.ireland.code
  alias  = "awsireland"
}

# Provider definition for N. Virginia Region
provider "aws" {
  region = var.aws_regions.nvirginia.code
  alias  = "awsnvirginia"
}

# Provider definition for Sydney Region
provider "aws" {
  region = var.aws_regions.sydney.code
  alias  = "awssydney"
}