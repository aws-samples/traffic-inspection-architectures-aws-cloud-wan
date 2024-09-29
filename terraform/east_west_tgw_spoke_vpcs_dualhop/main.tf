/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- east_west_tgw_spoke_vpcs_dualhop/main.tf ---

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

  create_base_policy   = true
  base_policy_document = data.aws_networkmanager_core_network_policy_document.base_policy.json

  tags = {
    Name = "Core Network - ${var.identifier}"
  }
}

# Core Network Policy Attachment
resource "aws_networkmanager_core_network_policy_attachment" "core_network_policy_attachment" {
  provider = aws.awsnvirginia

  core_network_id = aws_networkmanager_core_network.core_network.id
  policy_document = data.aws_networkmanager_core_network_policy_document.policy.json

  depends_on = [
    module.ireland_cwan_inspection_vpc,
    module.nvirginia_cwan_inspection_vpc,
    module.sydney_cwan_inspection_vpc,
    module.ireland_transit_gateway,
    module.nvirginia_transit_gateway,
    module.sydney_transit_gateway
  ]
}

# ---------- RESOURCES IN IRELAND ----------
# Spoke VPCs - definition in variables.tf
module "ireland_spoke_vpcs" {
  for_each  = var.ireland_spoke_vpcs
  source    = "aws-ia/vpc/aws"
  version   = "= 4.4.2"
  providers = { aws = aws.awsireland }

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = each.value.number_azs

  transit_gateway_id = module.ireland_transit_gateway.transit_gateway_id
  transit_gateway_routes = {
    workload = "0.0.0.0/0"
  }

  subnets = {
    endpoints       = { netmask = each.value.endpoint_subnet_netmask }
    workload        = { netmask = each.value.workload_subnet_netmask }
    transit_gateway = { netmask = each.value.tgw_subnet_netmask }
  }
}

# Inspection VPC (AWS Transit Gateway) - definition in variables.tf
module "ireland_tgw_inspection_vpc" {
  source    = "aws-ia/vpc/aws"
  version   = "= 4.4.2"
  providers = { aws = aws.awsireland }

  name       = "${var.ireland_inspection_vpc.name}-tgw"
  cidr_block = var.ireland_inspection_vpc.cidr_block
  az_count   = var.ireland_inspection_vpc.number_azs

  transit_gateway_id = module.ireland_transit_gateway.transit_gateway_id
  transit_gateway_routes = {
    inspection = "0.0.0.0/0"
  }

  subnets = {
    inspection = { netmask = var.ireland_inspection_vpc.inspection_subnet_netmask }
    transit_gateway = {
      netmask                                = var.ireland_inspection_vpc.connectivity_subnet_netmask
      transit_gateway_appliance_mode_support = "enable"
    }
  }
}

module "ireland_tgw_network_firewall" {
  source    = "aws-ia/networkfirewall/aws"
  version   = "1.0.0"
  providers = { aws = aws.awsireland }

  network_firewall_name        = "anfw-ireland-tgw"
  network_firewall_description = "AWS Network Firewall (Ireland) - Transit Gateway"
  network_firewall_policy      = module.ireland_anfw_policy.policy_arn

  vpc_id      = module.ireland_tgw_inspection_vpc.vpc_attributes.id
  number_azs  = var.ireland_inspection_vpc.number_azs
  vpc_subnets = { for k, v in module.ireland_tgw_inspection_vpc.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "inspection" }

  routing_configuration = {
    centralized_inspection_without_egress = {
      connectivity_subnet_route_tables = { for k, v in module.ireland_tgw_inspection_vpc.rt_attributes_by_type_by_az.transit_gateway : k => v.id }
    }
  }
}

# Inspection VPC (AWS Cloud WAN) - definition in variables.tf
module "ireland_cwan_inspection_vpc" {
  source    = "aws-ia/cloudwan/aws"
  version   = "3.2.0"
  providers = { aws = aws.awsireland }

  core_network_arn = aws_networkmanager_core_network.core_network.arn

  central_vpcs = {
    inspection = {
      type       = "inspection"
      name       = "${var.ireland_inspection_vpc.name}-cwan"
      cidr_block = var.ireland_inspection_vpc.cidr_block
      az_count   = var.ireland_inspection_vpc.number_azs

      subnets = {
        endpoints = { netmask = var.ireland_inspection_vpc.inspection_subnet_netmask }
        core_network = {
          netmask = var.ireland_inspection_vpc.connectivity_subnet_netmask

          tags = { inspection = "true" }
        }
      }
    }
  }

  aws_network_firewall = {
    inspection = {
      name        = "anfw-ireland-cwan"
      description = "AWS Network Firewall (Ireland) - Cloud WAN"
      policy_arn  = module.ireland_anfw_policy.policy_arn
    }
  }
}

# AWS Network Firewall policy
module "ireland_anfw_policy" {
  source    = "../modules/firewall_policy"
  providers = { aws = aws.awsireland }

  identifier   = var.identifier
  traffic_flow = "east-west"
}

# Transit Gateway resources (RT, Association, Propagation and Cloud WAN peering)
module "ireland_transit_gateway" {
  source    = "./modules/transit_gateway"
  providers = { aws = aws.awsireland }

  identifier      = var.identifier
  tgw_asn         = var.aws_regions.ireland.tgw_asn
  core_network_id = aws_networkmanager_core_network.core_network.id
  spoke_vpc_information = { for k, v in module.ireland_spoke_vpcs : k => {
    segment                       = var.ireland_spoke_vpcs[k].segment
    transit_gateway_attachment_id = v.transit_gateway_attachment_id
  } }
  inspection_vpc_tgw_attachment = module.ireland_tgw_inspection_vpc.transit_gateway_attachment_id
}

# EC2 Instances (in Spoke VPCs) and EC2 Instance Connect endpoint
module "ireland_compute" {
  for_each  = module.ireland_spoke_vpcs
  source    = "../modules/compute"
  providers = { aws = aws.awsireland }

  identifier      = var.identifier
  vpc_name        = each.key
  vpc             = each.value
  vpc_information = var.ireland_spoke_vpcs[each.key]
}

# ---------- RESOURCES IN N. VIRGINIA ----------
# Spoke VPCs - definition in variables.tf
module "nvirginia_spoke_vpcs" {
  for_each  = var.nvirginia_spoke_vpcs
  source    = "aws-ia/vpc/aws"
  version   = "= 4.4.2"
  providers = { aws = aws.awsnvirginia }

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = each.value.number_azs

  transit_gateway_id = module.nvirginia_transit_gateway.transit_gateway_id
  transit_gateway_routes = {
    workload = "0.0.0.0/0"
  }

  subnets = {
    endpoints       = { netmask = each.value.endpoint_subnet_netmask }
    workload        = { netmask = each.value.workload_subnet_netmask }
    transit_gateway = { netmask = each.value.tgw_subnet_netmask }
  }
}

# Inspection VPC (AWS Transit Gateway) - definition in variables.tf
module "nvirginia_tgw_inspection_vpc" {
  source    = "aws-ia/vpc/aws"
  version   = "= 4.4.2"
  providers = { aws = aws.awsnvirginia }

  name       = "${var.nvirginia_inspection_vpc.name}-tgw"
  cidr_block = var.nvirginia_inspection_vpc.cidr_block
  az_count   = var.nvirginia_inspection_vpc.number_azs

  transit_gateway_id = module.nvirginia_transit_gateway.transit_gateway_id
  transit_gateway_routes = {
    inspection = "0.0.0.0/0"
  }

  subnets = {
    inspection = { netmask = var.nvirginia_inspection_vpc.inspection_subnet_netmask }
    transit_gateway = {
      netmask                                = var.nvirginia_inspection_vpc.connectivity_subnet_netmask
      transit_gateway_appliance_mode_support = "enable"
    }
  }
}

module "nvirginia_tgw_network_firewall" {
  source    = "aws-ia/networkfirewall/aws"
  version   = "1.0.0"
  providers = { aws = aws.awsnvirginia }

  network_firewall_name        = "anfw-nvirginia-tgw"
  network_firewall_description = "AWS Network Firewall (N. Virginia) - Transit Gateway"
  network_firewall_policy      = module.nvirginia_anfw_policy.policy_arn

  vpc_id      = module.nvirginia_tgw_inspection_vpc.vpc_attributes.id
  number_azs  = var.nvirginia_inspection_vpc.number_azs
  vpc_subnets = { for k, v in module.nvirginia_tgw_inspection_vpc.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "inspection" }

  routing_configuration = {
    centralized_inspection_without_egress = {
      connectivity_subnet_route_tables = { for k, v in module.nvirginia_tgw_inspection_vpc.rt_attributes_by_type_by_az.transit_gateway : k => v.id }
    }
  }
}

# Inspection VPC (AWS Cloud WAN) - definition in variables.tf
module "nvirginia_cwan_inspection_vpc" {
  source    = "aws-ia/cloudwan/aws"
  version   = "3.2.0"
  providers = { aws = aws.awsnvirginia }

  core_network_arn = aws_networkmanager_core_network.core_network.arn

  central_vpcs = {
    inspection = {
      type       = "inspection"
      name       = "${var.nvirginia_inspection_vpc.name}-cwan"
      cidr_block = var.nvirginia_inspection_vpc.cidr_block
      az_count   = var.nvirginia_inspection_vpc.number_azs

      subnets = {
        endpoints = { netmask = var.nvirginia_inspection_vpc.inspection_subnet_netmask }
        core_network = {
          netmask = var.nvirginia_inspection_vpc.connectivity_subnet_netmask

          tags = { inspection = "true" }
        }
      }
    }
  }

  aws_network_firewall = {
    inspection = {
      name        = "anfw-nvirginia-cwan"
      description = "AWS Network Firewall (N. Virginia) - Cloud WAN"
      policy_arn  = module.nvirginia_anfw_policy.policy_arn
    }
  }
}

# AWS Network Firewall policy
module "nvirginia_anfw_policy" {
  source    = "../modules/firewall_policy"
  providers = { aws = aws.awsnvirginia }

  identifier   = var.identifier
  traffic_flow = "east-west"
}

# Transit Gateway resources (RT, Association, Propagation and Cloud WAN peering)
module "nvirginia_transit_gateway" {
  source    = "./modules/transit_gateway"
  providers = { aws = aws.awsnvirginia }

  identifier      = var.identifier
  tgw_asn         = var.aws_regions.nvirginia.tgw_asn
  core_network_id = aws_networkmanager_core_network.core_network.id
  spoke_vpc_information = { for k, v in module.nvirginia_spoke_vpcs : k => {
    segment                       = var.nvirginia_spoke_vpcs[k].segment
    transit_gateway_attachment_id = v.transit_gateway_attachment_id
  } }
  inspection_vpc_tgw_attachment = module.nvirginia_tgw_inspection_vpc.transit_gateway_attachment_id
}

# EC2 Instances (in Spoke VPCs) and EC2 Instance Connect endpoint
module "nvirginia_compute" {
  for_each  = module.nvirginia_spoke_vpcs
  source    = "../modules/compute"
  providers = { aws = aws.awsnvirginia }

  identifier      = var.identifier
  vpc_name        = each.key
  vpc             = each.value
  vpc_information = var.nvirginia_spoke_vpcs[each.key]
}

# ---------- RESOURCES IN SYDNEY ----------
# Spoke VPCs - definition in variables.tf
module "sydney_spoke_vpcs" {
  for_each  = var.sydney_spoke_vpcs
  source    = "aws-ia/vpc/aws"
  version   = "= 4.4.2"
  providers = { aws = aws.awssydney }

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = each.value.number_azs

  transit_gateway_id = module.sydney_transit_gateway.transit_gateway_id
  transit_gateway_routes = {
    workload = "0.0.0.0/0"
  }

  subnets = {
    endpoints       = { netmask = each.value.endpoint_subnet_netmask }
    workload        = { netmask = each.value.workload_subnet_netmask }
    transit_gateway = { netmask = each.value.tgw_subnet_netmask }
  }
}

# Inspection VPC (AWS Transit Gateway) - definition in variables.tf
module "sydney_tgw_inspection_vpc" {
  source    = "aws-ia/vpc/aws"
  version   = "= 4.4.2"
  providers = { aws = aws.awssydney }

  name       = "${var.sydney_inspection_vpc.name}-tgw"
  cidr_block = var.sydney_inspection_vpc.cidr_block
  az_count   = var.sydney_inspection_vpc.number_azs

  transit_gateway_id = module.sydney_transit_gateway.transit_gateway_id
  transit_gateway_routes = {
    inspection = "0.0.0.0/0"
  }

  subnets = {
    inspection = { netmask = var.sydney_inspection_vpc.inspection_subnet_netmask }
    transit_gateway = {
      netmask                                = var.sydney_inspection_vpc.connectivity_subnet_netmask
      transit_gateway_appliance_mode_support = "enable"
    }
  }
}

module "sydney_tgw_network_firewall" {
  source    = "aws-ia/networkfirewall/aws"
  version   = "1.0.0"
  providers = { aws = aws.awssydney }

  network_firewall_name        = "anfw-sydney-tgw"
  network_firewall_description = "AWS Network Firewall (Sydney) - Transit Gateway"
  network_firewall_policy      = module.sydney_anfw_policy.policy_arn

  vpc_id      = module.sydney_tgw_inspection_vpc.vpc_attributes.id
  number_azs  = var.sydney_inspection_vpc.number_azs
  vpc_subnets = { for k, v in module.sydney_tgw_inspection_vpc.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "inspection" }

  routing_configuration = {
    centralized_inspection_without_egress = {
      connectivity_subnet_route_tables = { for k, v in module.sydney_tgw_inspection_vpc.rt_attributes_by_type_by_az.transit_gateway : k => v.id }
    }
  }
}

# Inspection VPC (AWS Cloud WAN) - definition in variables.tf
module "sydney_cwan_inspection_vpc" {
  source    = "aws-ia/cloudwan/aws"
  version   = "3.2.0"
  providers = { aws = aws.awssydney }

  core_network_arn = aws_networkmanager_core_network.core_network.arn

  central_vpcs = {
    inspection = {
      type       = "inspection"
      name       = "${var.sydney_inspection_vpc.name}-cwan"
      cidr_block = var.sydney_inspection_vpc.cidr_block
      az_count   = var.sydney_inspection_vpc.number_azs

      subnets = {
        endpoints = { netmask = var.sydney_inspection_vpc.inspection_subnet_netmask }
        core_network = {
          netmask = var.sydney_inspection_vpc.connectivity_subnet_netmask

          tags = { inspection = "true" }
        }
      }
    }
  }

  aws_network_firewall = {
    inspection = {
      name        = "anfw-sydney-cwan"
      description = "AWS Network Firewall (Sydney) - Cloud WAN"
      policy_arn  = module.sydney_anfw_policy.policy_arn
    }
  }
}

# AWS Network Firewall policy
module "sydney_anfw_policy" {
  source    = "../modules/firewall_policy"
  providers = { aws = aws.awssydney }

  identifier   = var.identifier
  traffic_flow = "east-west"
}

# Transit Gateway resources (RT, Association, Propagation and Cloud WAN peering)
module "sydney_transit_gateway" {
  source    = "./modules/transit_gateway"
  providers = { aws = aws.awssydney }

  identifier      = var.identifier
  tgw_asn         = var.aws_regions.sydney.tgw_asn
  core_network_id = aws_networkmanager_core_network.core_network.id
  spoke_vpc_information = { for k, v in module.sydney_spoke_vpcs : k => {
    segment                       = var.sydney_spoke_vpcs[k].segment
    transit_gateway_attachment_id = v.transit_gateway_attachment_id
  } }
  inspection_vpc_tgw_attachment = module.sydney_tgw_inspection_vpc.transit_gateway_attachment_id
}

# EC2 Instances (in Spoke VPCs) and EC2 Instance Connect endpoint
module "sydney_compute" {
  for_each  = module.sydney_spoke_vpcs
  source    = "../modules/compute"
  providers = { aws = aws.awssydney }

  identifier      = var.identifier
  vpc_name        = each.key
  vpc             = each.value
  vpc_information = var.sydney_spoke_vpcs[each.key]
}