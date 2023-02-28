/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- east_west_tgw/main.tf ---

# ---------- AWS CLOUD WAN RESOURCES ----------
# Global Network
resource "aws_networkmanager_global_network" "global_network" {
  provider = aws.awsnvirginia

  description = "Global Network - ${var.identifier}"

  tags = {
    Name = "Global Network - ${var.identifier}"
  }
}

# Core Network
resource "aws_networkmanager_core_network" "core_network" {
  provider = aws.awsnvirginia

  description       = "Core Network - ${var.identifier}"
  global_network_id = aws_networkmanager_global_network.global_network.id
  policy_document   = jsonencode(jsondecode(data.aws_networkmanager_core_network_policy_document.core_network_policy.json))

  tags = {
    Name = "Core Network - ${var.identifier}"
  }
}

# ---------- GLOBAL RESOURCES - IAM ROLES ----------
# EC2 IAM Instance Profile & VPC Flow Logs IAM Role
module "iam" {
  source = "../modules/iam"

  identifier = var.identifier
}

# ---------- RESOURCES IN IRELAND ----------
# Spoke VPCs - definition in variables.tf
module "ireland_spoke_vpcs" {
  for_each  = var.ireland_spoke_vpcs
  source    = "aws-ia/vpc/aws"
  version   = "= 4.0.0"
  providers = { aws = aws.awsireland }

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = each.value.number_azs

  transit_gateway_id = module.ireland_transit_gateway.transit_gateway_id
  transit_gateway_routes = {
    workload = "0.0.0.0/0"
  }

  subnets = {
    vpc_endpoints   = { netmask = each.value.endpoint_subnet_netmask }
    workload        = { netmask = each.value.workload_subnet_netmask }
    transit_gateway = { netmask = each.value.tgw_subnet_netmask }
  }
}

# Inspection VPC - definition in variables.tf
module "ireland_inspection_vpc" {
  source    = "aws-ia/vpc/aws"
  version   = "= 4.0.0"
  providers = { aws = aws.awsireland }

  name       = var.ireland_inspection_vpc.name
  cidr_block = var.ireland_inspection_vpc.cidr_block
  az_count   = var.ireland_inspection_vpc.number_azs

  transit_gateway_id = module.ireland_transit_gateway.transit_gateway_id
  transit_gateway_routes = {
    inspection = "10.0.0.0/8"
  }

  subnets = {
    inspection = { netmask = var.ireland_inspection_vpc.inspection_subnet_netmask }
    transit_gateway = {
      netmask                                = var.ireland_inspection_vpc.tgw_subnet_netmask
      transit_gateway_appliance_mode_support = "enable"
    }
  }
}

# Prefix List - Including all the Spoke VPC CIDRs blocks
resource "aws_ec2_managed_prefix_list" "ireland_prefix_list" {
  provider = aws.awsireland

  name           = "Spoke VPCs Prefix List - Ireland"
  address_family = "IPv4"
  max_entries    = length(var.ireland_spoke_vpcs)
}

resource "aws_ec2_managed_prefix_list_entry" "ireland_pl_entry" {
  provider = aws.awsireland
  for_each = var.ireland_spoke_vpcs

  cidr           = each.value.cidr_block
  description    = each.key
  prefix_list_id = aws_ec2_managed_prefix_list.ireland_prefix_list.id
}

# Transit Gateway resources (RT, Association, Propagation and Cloud WAN peering)
module "ireland_transit_gateway" {
  source    = "./modules/transit_gateway"
  providers = { aws = aws.awsireland }

  identifier                   = var.identifier
  aws_region                   = "ireland"
  tgw_asn                      = var.aws_regions.ireland.tgw_asn
  spokes_prefix_list           = aws_ec2_managed_prefix_list.ireland_prefix_list.id
  spoke_vpc_tgw_attachment_ids = { for k, v in module.ireland_spoke_vpcs : k => v.transit_gateway_attachment_id }
  inspection_vpc_attachment_id = module.ireland_inspection_vpc.transit_gateway_attachment_id
  core_network_id              = aws_networkmanager_core_network.core_network.id
}

# AWS Network Firewall resources (and routing)
module "ireland_inspection" {
  source    = "./modules/inspection"
  providers = { aws = aws.awsireland }

  identifier = var.identifier
  vpc        = module.ireland_inspection_vpc
  number_azs = var.ireland_inspection_vpc.number_azs
}

# EC2 Instances (in Spoke VPCs)
module "ireland_compute" {
  for_each  = module.ireland_spoke_vpcs
  source    = "../modules/compute"
  providers = { aws = aws.awsireland }

  identifier               = var.identifier
  vpc_name                 = var.ireland_spoke_vpcs[each.key].name
  vpc_id                   = each.value.vpc_attributes.id
  vpc_subnets              = values({ for k, v in each.value.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "workload" })
  number_azs               = var.ireland_spoke_vpcs[each.key].number_azs
  instance_type            = var.ireland_spoke_vpcs[each.key].instance_type
  ec2_iam_instance_profile = module.iam.ec2_iam_instance_profile
  ingress_vpc_cidr         = var.ireland_inspection_vpc.cidr_block
}

# SSM VPC endpoints (in Spoke VPCs)
module "ireland_endpoints" {
  for_each  = module.ireland_spoke_vpcs
  source    = "../modules/endpoints"
  providers = { aws = aws.awsireland }

  identifier  = var.identifier
  vpc_name    = var.ireland_spoke_vpcs[each.key].name
  vpc_id      = each.value.vpc_attributes.id
  vpc_cidr    = var.ireland_spoke_vpcs[each.key].cidr_block
  vpc_subnets = values({ for k, v in each.value.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "vpc_endpoints" })
  aws_region  = var.aws_regions.ireland.code
}

# ---------- RESOURCES IN N. VIRGINIA ----------
# Spoke VPCs - definition in variables.tf
module "nvirginia_spoke_vpcs" {
  for_each  = var.nvirginia_spoke_vpcs
  source    = "aws-ia/vpc/aws"
  version   = "= 4.0.0"
  providers = { aws = aws.awsnvirginia }

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = each.value.number_azs

  transit_gateway_id = module.nvirginia_transit_gateway.transit_gateway_id
  transit_gateway_routes = {
    workload = "0.0.0.0/0"
  }

  subnets = {
    vpc_endpoints   = { netmask = each.value.endpoint_subnet_netmask }
    workload        = { netmask = each.value.workload_subnet_netmask }
    transit_gateway = { netmask = each.value.tgw_subnet_netmask }
  }
}

# Inspection VPC - definition in variables.tf
module "nvirginia_inspection_vpc" {
  source    = "aws-ia/vpc/aws"
  version   = "= 4.0.0"
  providers = { aws = aws.awsnvirginia }

  name       = var.nvirginia_inspection_vpc.name
  cidr_block = var.nvirginia_inspection_vpc.cidr_block
  az_count   = var.nvirginia_inspection_vpc.number_azs

  transit_gateway_id = module.nvirginia_transit_gateway.transit_gateway_id
  transit_gateway_routes = {
    inspection = "10.0.0.0/8"
  }

  subnets = {
    inspection = { netmask = var.nvirginia_inspection_vpc.inspection_subnet_netmask }
    transit_gateway = {
      netmask                                = var.nvirginia_inspection_vpc.tgw_subnet_netmask
      transit_gateway_appliance_mode_support = "enable"
    }
  }
}

# Prefix List - Including all the Spoke VPC CIDRs blocks
resource "aws_ec2_managed_prefix_list" "nvirginia_prefix_list" {
  provider = aws.awsnvirginia

  name           = "Spoke VPCs Prefix List - N. Virginia"
  address_family = "IPv4"
  max_entries    = length(var.nvirginia_spoke_vpcs)
}

resource "aws_ec2_managed_prefix_list_entry" "nvirginia_pl_entry" {
  provider = aws.awsnvirginia
  for_each = var.nvirginia_spoke_vpcs

  cidr           = each.value.cidr_block
  description    = each.key
  prefix_list_id = aws_ec2_managed_prefix_list.nvirginia_prefix_list.id
}

# Transit Gateway resources (RT, Association, Propagation and Cloud WAN peering)
module "nvirginia_transit_gateway" {
  source    = "./modules/transit_gateway"
  providers = { aws = aws.awsnvirginia }

  identifier                   = var.identifier
  aws_region                   = "nvirginia"
  tgw_asn                      = var.aws_regions.nvirginia.tgw_asn
  spokes_prefix_list           = aws_ec2_managed_prefix_list.nvirginia_prefix_list.id
  spoke_vpc_tgw_attachment_ids = { for k, v in module.nvirginia_spoke_vpcs : k => v.transit_gateway_attachment_id }
  inspection_vpc_attachment_id = module.nvirginia_inspection_vpc.transit_gateway_attachment_id
  core_network_id              = aws_networkmanager_core_network.core_network.id
}

# AWS Network Firewall resources (and routing)
module "nvirginia_inspection" {
  source    = "./modules/inspection"
  providers = { aws = aws.awsnvirginia }

  identifier = var.identifier
  vpc        = module.nvirginia_inspection_vpc
  number_azs = var.nvirginia_inspection_vpc.number_azs
}

# EC2 Instances (in Spoke VPCs)
module "nvirginia_compute" {
  for_each  = module.nvirginia_spoke_vpcs
  source    = "../modules/compute"
  providers = { aws = aws.awsnvirginia }

  identifier               = var.identifier
  vpc_name                 = var.nvirginia_spoke_vpcs[each.key].name
  vpc_id                   = each.value.vpc_attributes.id
  vpc_subnets              = values({ for k, v in each.value.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "workload" })
  number_azs               = var.nvirginia_spoke_vpcs[each.key].number_azs
  instance_type            = var.nvirginia_spoke_vpcs[each.key].instance_type
  ec2_iam_instance_profile = module.iam.ec2_iam_instance_profile
  ingress_vpc_cidr         = var.nvirginia_inspection_vpc.cidr_block
}

# SSM VPC endpoints (in Spoke VPCs)
module "nvirginia_endpoints" {
  for_each  = module.nvirginia_spoke_vpcs
  source    = "../modules/endpoints"
  providers = { aws = aws.awsnvirginia }

  identifier  = var.identifier
  vpc_name    = var.nvirginia_spoke_vpcs[each.key].name
  vpc_id      = each.value.vpc_attributes.id
  vpc_cidr    = var.nvirginia_spoke_vpcs[each.key].cidr_block
  vpc_subnets = values({ for k, v in each.value.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "vpc_endpoints" })
  aws_region  = var.aws_regions.nvirginia.code
}

# ---------- RESOURCES IN SYDNEY ----------
# Spoke VPCs - definition in variables.tf
module "sydney_spoke_vpcs" {
  for_each  = var.sydney_spoke_vpcs
  source    = "aws-ia/vpc/aws"
  version   = "= 4.0.0"
  providers = { aws = aws.awssydney }

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = each.value.number_azs

  transit_gateway_id = module.sydney_transit_gateway.transit_gateway_id
  transit_gateway_routes = {
    workload = "0.0.0.0/0"
  }

  subnets = {
    vpc_endpoints   = { netmask = each.value.endpoint_subnet_netmask }
    workload        = { netmask = each.value.workload_subnet_netmask }
    transit_gateway = { netmask = each.value.tgw_subnet_netmask }
  }
}

# Inspection VPC - definition in variables.tf
module "sydney_inspection_vpc" {
  source    = "aws-ia/vpc/aws"
  version   = "= 4.0.0"
  providers = { aws = aws.awssydney }

  name       = var.sydney_inspection_vpc.name
  cidr_block = var.sydney_inspection_vpc.cidr_block
  az_count   = var.sydney_inspection_vpc.number_azs

  transit_gateway_id = module.sydney_transit_gateway.transit_gateway_id
  transit_gateway_routes = {
    inspection = "10.0.0.0/8"
  }

  subnets = {
    inspection = { netmask = var.sydney_inspection_vpc.inspection_subnet_netmask }
    transit_gateway = {
      netmask                                = var.sydney_inspection_vpc.tgw_subnet_netmask
      transit_gateway_appliance_mode_support = "enable"
    }
  }
}

# Prefix List - Including all the Spoke VPC CIDRs blocks
resource "aws_ec2_managed_prefix_list" "sydney_prefix_list" {
  provider = aws.awssydney

  name           = "Spoke VPCs Prefix List - N. Virginia"
  address_family = "IPv4"
  max_entries    = length(var.sydney_spoke_vpcs)
}

resource "aws_ec2_managed_prefix_list_entry" "sydney_pl_entry" {
  provider = aws.awssydney
  for_each = var.sydney_spoke_vpcs

  cidr           = each.value.cidr_block
  description    = each.key
  prefix_list_id = aws_ec2_managed_prefix_list.sydney_prefix_list.id
}

# Transit Gateway resources (RT, Association, Propagation and Cloud WAN peering)
module "sydney_transit_gateway" {
  source    = "./modules/transit_gateway"
  providers = { aws = aws.awssydney }

  identifier                   = var.identifier
  aws_region                   = "sydney"
  tgw_asn                      = var.aws_regions.sydney.tgw_asn
  spokes_prefix_list           = aws_ec2_managed_prefix_list.sydney_prefix_list.id
  spoke_vpc_tgw_attachment_ids = { for k, v in module.sydney_spoke_vpcs : k => v.transit_gateway_attachment_id }
  inspection_vpc_attachment_id = module.sydney_inspection_vpc.transit_gateway_attachment_id
  core_network_id              = aws_networkmanager_core_network.core_network.id
}

# AWS Network Firewall resources (and routing)
module "sydney_inspection" {
  source    = "./modules/inspection"
  providers = { aws = aws.awssydney }

  identifier = var.identifier
  vpc        = module.sydney_inspection_vpc
  number_azs = var.sydney_inspection_vpc.number_azs
}

# EC2 Instances (in Spoke VPCs)
module "sydney_compute" {
  for_each  = module.sydney_spoke_vpcs
  source    = "../modules/compute"
  providers = { aws = aws.awssydney }

  identifier               = var.identifier
  vpc_name                 = var.sydney_spoke_vpcs[each.key].name
  vpc_id                   = each.value.vpc_attributes.id
  vpc_subnets              = values({ for k, v in each.value.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "workload" })
  number_azs               = var.sydney_spoke_vpcs[each.key].number_azs
  instance_type            = var.sydney_spoke_vpcs[each.key].instance_type
  ec2_iam_instance_profile = module.iam.ec2_iam_instance_profile
  ingress_vpc_cidr         = var.sydney_inspection_vpc.cidr_block
}

# SSM VPC endpoints (in Spoke VPCs)
module "sydney_endpoints" {
  for_each  = module.sydney_spoke_vpcs
  source    = "../modules/endpoints"
  providers = { aws = aws.awssydney }

  identifier  = var.identifier
  vpc_name    = var.sydney_spoke_vpcs[each.key].name
  vpc_id      = each.value.vpc_attributes.id
  vpc_cidr    = var.sydney_spoke_vpcs[each.key].cidr_block
  vpc_subnets = values({ for k, v in each.value.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "vpc_endpoints" })
  aws_region  = var.aws_regions.sydney.code
}

