/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- east_west_tgw_spoke_vpcs/main.tf ---

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

  tags = {
    Name = "Core Network - ${var.identifier}"
  }
}

# Core Network Policy Attachment
resource "aws_networkmanager_core_network_policy_attachment" "core_network_policy_attachment" {
  provider = aws.awsnvirginia

  core_network_id = aws_networkmanager_core_network.core_network.id
  policy_document = jsonencode(jsondecode(data.aws_networkmanager_core_network_policy_document.core_network_policy.json))
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

  core_network = {
    id  = aws_networkmanager_core_network.core_network.id
    arn = aws_networkmanager_core_network.core_network.arn
  }
  core_network_routes = {
    inspection = "0.0.0.0/0"
  }

  subnets = {
    inspection = { netmask = var.ireland_inspection_vpc.inspection_subnet_netmask }
    core_network = {
      netmask            = var.ireland_inspection_vpc.cnetwork_subnet_netmask
      ipv6_support       = false
      require_acceptance = false

      tags = {
        domain = "postinspectionireland"
      }
    }
  }
}

# Transit Gateway resources (RT, Association, Propagation and Cloud WAN peering)
module "ireland_transit_gateway" {
  source    = "./modules/transit_gateway"
  providers = { aws = aws.awsireland }

  identifier                   = var.identifier
  aws_region                   = "ireland"
  tgw_asn                      = var.aws_regions.ireland.tgw_asn
  spoke_vpc_tgw_attachment_ids = { for k, v in module.ireland_spoke_vpcs : k => v.transit_gateway_attachment_id }
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

  core_network = {
    id  = aws_networkmanager_core_network.core_network.id
    arn = aws_networkmanager_core_network.core_network.arn
  }
  core_network_routes = {
    inspection = "0.0.0.0/0"
  }

  subnets = {
    inspection = { netmask = var.nvirginia_inspection_vpc.inspection_subnet_netmask }
    core_network = {
      netmask            = var.nvirginia_inspection_vpc.cnetwork_subnet_netmask
      ipv6_support       = false
      require_acceptance = false

      tags = {
        domain = "postinspectionnvirginia"
      }
    }
  }
}

# Transit Gateway resources (RT, Association, Propagation and Cloud WAN peering)
module "nvirginia_transit_gateway" {
  source    = "./modules/transit_gateway"
  providers = { aws = aws.awsnvirginia }

  identifier                   = var.identifier
  aws_region                   = "nvirginia"
  tgw_asn                      = var.aws_regions.nvirginia.tgw_asn
  spoke_vpc_tgw_attachment_ids = { for k, v in module.nvirginia_spoke_vpcs : k => v.transit_gateway_attachment_id }
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

  core_network = {
    id  = aws_networkmanager_core_network.core_network.id
    arn = aws_networkmanager_core_network.core_network.arn
  }
  core_network_routes = {
    inspection = "0.0.0.0/0"
  }

  subnets = {
    inspection = { netmask = var.sydney_inspection_vpc.inspection_subnet_netmask }
    core_network = {
      netmask            = var.sydney_inspection_vpc.cnetwork_subnet_netmask
      ipv6_support       = false
      require_acceptance = false

      tags = {
        domain = "postinspectionsydney"
      }
    }
  }
}

# Transit Gateway resources (RT, Association, Propagation and Cloud WAN peering)
module "sydney_transit_gateway" {
  source    = "./modules/transit_gateway"
  providers = { aws = aws.awssydney }

  identifier                   = var.identifier
  aws_region                   = "sydney"
  tgw_asn                      = var.aws_regions.sydney.tgw_asn
  spoke_vpc_tgw_attachment_ids = { for k, v in module.sydney_spoke_vpcs : k => v.transit_gateway_attachment_id }
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

