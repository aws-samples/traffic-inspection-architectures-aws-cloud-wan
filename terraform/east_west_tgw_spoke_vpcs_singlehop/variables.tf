/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- east_west_tgw_spoke_vpcs_singlehop/variables.tf ---

# Project Identifier
variable "identifier" {
  type        = string
  description = "Project Identifier, used as identifer when creating resources."
  default     = "ew-tgw-spoke-vpcs"
}

# AWS Regions
variable "aws_regions" {
  type        = map(any)
  description = "AWS Regions to create the environment."
  default = {
    ireland = {
      code    = "eu-west-1"
      tgw_asn = 64515
    }
    nvirginia = {
      code    = "us-east-1"
      tgw_asn = 64516
    }
    sydney = {
      code    = "ap-southeast-2"
      tgw_asn = 64517
    }
  }
}

# Segment configuration - Core Network with a single segment or several ones
variable "segment_configuration" {
  type        = string
  description = "Core Network Segment configuration."
  default     = "default" # Expected values: default or isolated
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
      tgw_subnet_netmask      = 28
      instance_type           = "t2.micro"

      flow_log_config = {
        log_destination_type = "cloud-watch-logs"
        retention_in_days    = 7
      }
    }
    "dev" = {
      name                    = "dev-eu-west-1"
      segment                 = "development"
      number_azs              = 2
      cidr_block              = "10.0.1.0/24"
      workload_subnet_netmask = 28
      endpoint_subnet_netmask = 28
      tgw_subnet_netmask      = 28
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
      segment                 = "production"
      number_azs              = 2
      cidr_block              = "10.10.0.0/24"
      workload_subnet_netmask = 28
      endpoint_subnet_netmask = 28
      tgw_subnet_netmask      = 28
      instance_type           = "t2.micro"

      flow_log_config = {
        log_destination_type = "cloud-watch-logs"
        retention_in_days    = 7
      }
    }
    "dev" = {
      name                    = "dev-us-east-1"
      segment                 = "development"
      number_azs              = 2
      cidr_block              = "10.10.1.0/24"
      workload_subnet_netmask = 28
      endpoint_subnet_netmask = 28
      tgw_subnet_netmask      = 28
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
      segment                 = "production"
      number_azs              = 2
      cidr_block              = "10.20.0.0/24"
      workload_subnet_netmask = 28
      endpoint_subnet_netmask = 28
      tgw_subnet_netmask      = 28
      instance_type           = "t2.micro"

      flow_log_config = {
        log_destination_type = "cloud-watch-logs"
        retention_in_days    = 7
      }
    }
    "dev" = {
      name                    = "dev-ap-southeast-2"
      segment                 = "development"
      number_azs              = 2
      cidr_block              = "10.20.1.0/24"
      workload_subnet_netmask = 28
      endpoint_subnet_netmask = 28
      tgw_subnet_netmask      = 28
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
    inspection_subnet_netmask = 28
    cnetwork_subnet_netmask   = 28

    flow_log_config = {
      log_destination_type = "cloud-watch-logs"
      retention_in_days    = 7
    }
  }
}