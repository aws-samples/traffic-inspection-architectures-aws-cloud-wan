/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- centralized_outbound/variables.tf ---

# Project Identifier
variable "identifier" {
  type        = string
  description = "Project Identifier, used as identifer when creating resources."
  default     = "centralized-inbound"
}

# AWS Regions
variable "aws_regions" {
  type        = map(string)
  description = "AWS Regions to create the environment."
  default = {
    ireland   = "eu-west-1"
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
      segment                 = "prod"
      number_azs              = 2
      cidr_block              = "10.0.0.0/24"
      workload_subnet_netmask = 28
      endpoint_subnet_netmask = 28
      cnetwork_subnet_netmask = 28
      instance_type           = "t2.micro"

      flow_log_config = {
        log_destination_type = "cloud-watch-logs"
        retention_in_days    = 7
      }
    }
    "dev" = {
      name                    = "dev-eu-west-1"
      segment                 = "dev"
      number_azs              = 2
      cidr_block              = "10.0.1.0/24"
      workload_subnet_netmask = 28
      endpoint_subnet_netmask = 28
      cnetwork_subnet_netmask = 28
      instance_type           = "t2.micro"

      flow_log_config = {
        log_destination_type = "cloud-watch-logs"
        retention_in_days    = 7
      }
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

    flow_log_config = {
      log_destination_type = "cloud-watch-logs"
      retention_in_days    = 7
    }
  }
}

# Definition of the VPCs to create in N. Virginia Region
variable "nvirginia_spoke_vpcs" {
  type        = any
  description = "Information about the VPCs to create in us-east-1."

  default = {
    "prod" = {
      name                    = "prod-us-east-1"
      segment                 = "prod"
      number_azs              = 2
      cidr_block              = "10.10.0.0/24"
      workload_subnet_netmask = 28
      endpoint_subnet_netmask = 28
      cnetwork_subnet_netmask = 28
      instance_type           = "t2.micro"

      flow_log_config = {
        log_destination_type = "cloud-watch-logs"
        retention_in_days    = 7
      }
    }
    "dev" = {
      name                    = "dev-us-east-1"
      segment                 = "dev"
      number_azs              = 2
      cidr_block              = "10.10.1.0/24"
      workload_subnet_netmask = 28
      endpoint_subnet_netmask = 28
      cnetwork_subnet_netmask = 28
      instance_type           = "t2.micro"

      flow_log_config = {
        log_destination_type = "cloud-watch-logs"
        retention_in_days    = 7
      }
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

    flow_log_config = {
      log_destination_type = "cloud-watch-logs"
      retention_in_days    = 7
    }
  }
}

# Definition of the VPCs to create in Sydney Region
variable "sydney_spoke_vpcs" {
  type        = any
  description = "Information about the VPCs to create in ap-southeast-2."

  default = {
    "prod" = {
      name                    = "prod-ap-southeast-2"
      segment                 = "prod"
      number_azs              = 2
      cidr_block              = "10.20.0.0/24"
      workload_subnet_netmask = 28
      endpoint_subnet_netmask = 28
      cnetwork_subnet_netmask = 28
      instance_type           = "t2.micro"

      flow_log_config = {
        log_destination_type = "cloud-watch-logs"
        retention_in_days    = 7
      }
    }
    "dev" = {
      name                    = "dev-ap-southeast-2"
      segment                 = "dev"
      number_azs              = 2
      cidr_block              = "10.20.1.0/24"
      workload_subnet_netmask = 28
      endpoint_subnet_netmask = 28
      cnetwork_subnet_netmask = 28
      instance_type           = "t2.micro"

      flow_log_config = {
        log_destination_type = "cloud-watch-logs"
        retention_in_days    = 7
      }
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

    flow_log_config = {
      log_destination_type = "cloud-watch-logs"
      retention_in_days    = 7
    }
  }
}