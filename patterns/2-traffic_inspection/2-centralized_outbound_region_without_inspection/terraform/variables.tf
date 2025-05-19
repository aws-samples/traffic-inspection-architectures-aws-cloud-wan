/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- centralized_outbound_region_without_inspection/variables.tf ---

# Project Identifier
variable "identifier" {
  type        = string
  description = "Project Identifier, used as identifer when creating resources."
  default     = "centralized-outbound"
}

# AWS Regions
variable "aws_regions" {
  type        = map(string)
  description = "AWS Regions to create the environment."
  default = {
    ireland   = "eu-west-1"
    london    = "eu-west-2"
    nvirginia = "us-east-1"
    sydney    = "ap-southeast-2"
  }
}

# Definition of the VPCs to create in Ireland Region
variable "ireland_spoke_vpcs" {
  type        = any
  description = "Information about the VPCs to create in eu-west-1."

  default = {
    "prod" = {
      name                    = "prod-eu-west-1"
      segment                 = "production"
      number_azs              = 2
      cidr_block              = "10.0.0.0/24"
      workload_subnet_netmask = 28
      endpoint_subnet_netmask = 28
      cnetwork_subnet_netmask = 28
      instance_type           = "t2.micro"
    }
    "dev" = {
      name                    = "dev-eu-west-1"
      segment                 = "development"
      number_azs              = 2
      cidr_block              = "10.0.1.0/24"
      workload_subnet_netmask = 28
      endpoint_subnet_netmask = 28
      cnetwork_subnet_netmask = 28
      instance_type           = "t2.micro"
    }
  }
}

variable "ireland_inspection_vpc" {
  type        = any
  description = "Information about the Inspection VPC to create in eu-west-1."

  default = {
    name                      = "inspection-eu-west-1"
    cidr_block                = "10.100.0.0/16"
    number_azs                = 2
    public_subnet_netmask     = 28
    inspection_subnet_netmask = 28
    cnetwork_subnet_netmask   = 28
  }
}

# Definition of the VPCs to create in N. Virginia Region
variable "nvirginia_spoke_vpcs" {
  type        = any
  description = "Information about the VPCs to create in us-east-1."

  default = {
    "prod" = {
      name                    = "prod-us-east-1"
      segment                 = "production"
      number_azs              = 2
      cidr_block              = "10.10.0.0/24"
      workload_subnet_netmask = 28
      endpoint_subnet_netmask = 28
      cnetwork_subnet_netmask = 28
      instance_type           = "t2.micro"
    }
    "dev" = {
      name                    = "dev-us-east-1"
      segment                 = "development"
      number_azs              = 2
      cidr_block              = "10.10.1.0/24"
      workload_subnet_netmask = 28
      endpoint_subnet_netmask = 28
      cnetwork_subnet_netmask = 28
      instance_type           = "t2.micro"
    }
  }
}

variable "nvirginia_inspection_vpc" {
  type        = any
  description = "Information about the Inspection VPC to create in us-east-1."

  default = {
    name                      = "inspection-us-east-1"
    cidr_block                = "10.100.0.0/16"
    number_azs                = 2
    public_subnet_netmask     = 28
    inspection_subnet_netmask = 28
    cnetwork_subnet_netmask   = 28
  }
}

# Definition of the VPCs to create in Sydney Region
variable "sydney_spoke_vpcs" {
  type        = any
  description = "Information about the VPCs to create in ap-southeast-2."

  default = {
    "prod" = {
      name                    = "prod-ap-southeast-2"
      segment                 = "production"
      number_azs              = 2
      cidr_block              = "10.20.0.0/24"
      workload_subnet_netmask = 28
      endpoint_subnet_netmask = 28
      cnetwork_subnet_netmask = 28
      instance_type           = "t2.micro"
    }
    "dev" = {
      name                    = "dev-ap-southeast-2"
      segment                 = "development"
      number_azs              = 2
      cidr_block              = "10.20.1.0/24"
      workload_subnet_netmask = 28
      endpoint_subnet_netmask = 28
      cnetwork_subnet_netmask = 28
      instance_type           = "t2.micro"
    }
  }
}

variable "sydney_inspection_vpc" {
  type        = any
  description = "Information about the Inspection VPC to create in ap-southeast-2."

  default = {
    name                      = "insp-ap-southeast-2"
    cidr_block                = "10.100.0.0/16"
    number_azs                = 2
    public_subnet_netmask     = 28
    inspection_subnet_netmask = 28
    cnetwork_subnet_netmask   = 28
  }
}

# Definition of the VPCs to create in London Region
variable "london_spoke_vpcs" {
  type        = any
  description = "Information about the VPCs to create in eu-west-2."

  default = {
    "prod" = {
      name                    = "prod-eu-west-2"
      segment                 = "production"
      number_azs              = 2
      cidr_block              = "10.30.0.0/24"
      workload_subnet_netmask = 28
      endpoint_subnet_netmask = 28
      cnetwork_subnet_netmask = 28
      instance_type           = "t2.micro"
    }
    "dev" = {
      name                    = "dev-eu-west-2"
      segment                 = "development"
      number_azs              = 2
      cidr_block              = "10.30.1.0/24"
      workload_subnet_netmask = 28
      endpoint_subnet_netmask = 28
      cnetwork_subnet_netmask = 28
      instance_type           = "t2.micro"
    }
  }
}