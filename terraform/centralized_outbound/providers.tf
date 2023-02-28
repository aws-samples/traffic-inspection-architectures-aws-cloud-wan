/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- centralized_outbound/providers.tf ---

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.46.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = ">= 0.15.0"
    }
  }
}

# Provider definitios for Ireland Region
provider "aws" {
  region = var.aws_regions.ireland
  alias  = "awsireland"
}

provider "awscc" {
  region = var.aws_regions.ireland
  alias  = "awsccireland"
}

# Provider definitios for N. Virginia Region
provider "aws" {
  region = var.aws_regions.nvirginia
  alias  = "awsnvirginia"
}

provider "awscc" {
  region = var.aws_regions.nvirginia
  alias  = "awsccnvirginia"
}

# Provider definitios for Sydney Region
provider "aws" {
  region = var.aws_regions.sydney
  alias  = "awssydney"
}

provider "awscc" {
  region = var.aws_regions.sydney
  alias  = "awsccsydney"
}