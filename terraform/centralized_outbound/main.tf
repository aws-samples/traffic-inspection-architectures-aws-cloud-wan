/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- centralized_outbound/main.tf ---

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

  create_base_policy  = true
  base_policy_regions = values({ for k, v in var.aws_regions : k => v })

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
  version   = "= 4.3.0"
  providers = { aws = aws.awsireland }

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = each.value.number_azs

  core_network = {
    id  = aws_networkmanager_core_network.core_network.id
    arn = aws_networkmanager_core_network.core_network.arn
  }
  core_network_routes = {
    workload = "0.0.0.0/0"
  }

  subnets = {
    vpc_endpoints = { netmask = each.value.endpoint_subnet_netmask }
    workload      = { netmask = each.value.workload_subnet_netmask }
    core_network = {
      netmask            = each.value.cnetwork_subnet_netmask
      require_acceptance = false

      tags = {
        domain = each.value.segment
      }
    }
  }
}

# Inspection VPC - definition in variables.tf
module "ireland_inspection_vpc" {
  source    = "aws-ia/vpc/aws"
  version   = "= 4.3.0"
  providers = { aws = aws.awsireland }

  name       = var.ireland_inspection_vpc.name
  cidr_block = var.ireland_inspection_vpc.cidr_block
  az_count   = var.ireland_inspection_vpc.number_azs

  core_network = {
    id  = aws_networkmanager_core_network.core_network.id
    arn = aws_networkmanager_core_network.core_network.arn
  }
  core_network_routes = {
    inspection = "10.0.0.0/8"
  }

  subnets = {
    public = {
      netmask                   = var.ireland_inspection_vpc.public_subnet_netmask
      nat_gateway_configuration = "all_azs"
    }
    inspection = {
      netmask                 = var.ireland_inspection_vpc.inspection_subnet_netmask
      connect_to_public_natgw = true
    }
    core_network = {
      netmask            = var.ireland_inspection_vpc.cnetwork_subnet_netmask
      require_acceptance = false

      tags = {
        domain = "security"
      }
    }
  }
}

# AWS Network Firewall resources (and routing)
module "ireland_inspection" {
  source    = "./modules/inspection"
  providers = { aws = aws.awsireland }

  identifier          = var.identifier
  vpc                 = module.ireland_inspection_vpc
  number_azs          = var.ireland_inspection_vpc.number_azs
  network_cidr_blocks = ["10.0.0.0/8"]
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
  aws_region  = var.aws_regions.ireland
}

# ---------- RESOURCES IN N. VIRGINIA ----------
# Spoke VPCs - definition in variables.tf
module "nvirginia_spoke_vpcs" {
  for_each  = var.nvirginia_spoke_vpcs
  source    = "aws-ia/vpc/aws"
  version   = "= 4.3.0"
  providers = { aws = aws.awsnvirginia }

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = each.value.number_azs

  core_network = {
    id  = aws_networkmanager_core_network.core_network.id
    arn = aws_networkmanager_core_network.core_network.arn
  }
  core_network_routes = {
    workload = "0.0.0.0/0"
  }

  subnets = {
    vpc_endpoints = { netmask = each.value.endpoint_subnet_netmask }
    workload      = { netmask = each.value.workload_subnet_netmask }
    core_network = {
      netmask            = each.value.cnetwork_subnet_netmask
      require_acceptance = false

      tags = {
        domain = each.value.segment
      }
    }
  }
}

# Inspection VPC - definition in variables.tf
module "nvirginia_inspection_vpc" {
  source    = "aws-ia/vpc/aws"
  version   = "= 4.3.0"
  providers = { aws = aws.awsnvirginia }

  name       = var.nvirginia_inspection_vpc.name
  cidr_block = var.nvirginia_inspection_vpc.cidr_block
  az_count   = var.nvirginia_inspection_vpc.number_azs

  core_network = {
    id  = aws_networkmanager_core_network.core_network.id
    arn = aws_networkmanager_core_network.core_network.arn
  }
  core_network_routes = {
    inspection = "10.0.0.0/8"
  }

  subnets = {
    public = {
      netmask                   = var.nvirginia_inspection_vpc.public_subnet_netmask
      nat_gateway_configuration = "all_azs"
    }
    inspection = {
      netmask                 = var.nvirginia_inspection_vpc.inspection_subnet_netmask
      connect_to_public_natgw = true
    }
    core_network = {
      netmask            = var.nvirginia_inspection_vpc.cnetwork_subnet_netmask
      require_acceptance = false

      tags = {
        domain = "security"
      }
    }
  }
}

# AWS Network Firewall resources (and routing)
module "nvirginia_inspection" {
  source    = "./modules/inspection"
  providers = { aws = aws.awsnvirginia }

  identifier          = var.identifier
  vpc                 = module.nvirginia_inspection_vpc
  number_azs          = var.nvirginia_inspection_vpc.number_azs
  network_cidr_blocks = ["10.0.0.0/8"]
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
  aws_region  = var.aws_regions.nvirginia
}

# ---------- RESOURCES IN SYDNEY ----------
# Spoke VPCs - definition in variables.tf
module "sydney_spoke_vpcs" {
  for_each  = var.sydney_spoke_vpcs
  source    = "aws-ia/vpc/aws"
  version   = "= 4.3.0"
  providers = { aws = aws.awssydney }

  name       = each.key
  cidr_block = each.value.cidr_block
  az_count   = each.value.number_azs

  core_network = {
    id  = aws_networkmanager_core_network.core_network.id
    arn = aws_networkmanager_core_network.core_network.arn
  }
  core_network_routes = {
    workload = "0.0.0.0/0"
  }

  subnets = {
    vpc_endpoints = { netmask = each.value.endpoint_subnet_netmask }
    workload      = { netmask = each.value.workload_subnet_netmask }
    core_network = {
      netmask            = each.value.cnetwork_subnet_netmask
      require_acceptance = false

      tags = {
        domain = each.value.segment
      }
    }
  }
}

# Inspection VPC - definition in variables.tf
module "sydney_inspection_vpc" {
  source    = "aws-ia/vpc/aws"
  version   = "= 4.3.0"
  providers = { aws = aws.awssydney }

  name       = var.sydney_inspection_vpc.name
  cidr_block = var.sydney_inspection_vpc.cidr_block
  az_count   = var.sydney_inspection_vpc.number_azs

  core_network = {
    id  = aws_networkmanager_core_network.core_network.id
    arn = aws_networkmanager_core_network.core_network.arn
  }
  core_network_routes = {
    inspection = "10.0.0.0/8"
  }

  subnets = {
    public = {
      netmask                   = var.sydney_inspection_vpc.inspection_subnet_netmask
      nat_gateway_configuration = "all_azs"
    }
    inspection = {
      netmask                 = var.sydney_inspection_vpc.inspection_subnet_netmask
      connect_to_public_natgw = true
    }
    core_network = {
      netmask            = var.sydney_inspection_vpc.cnetwork_subnet_netmask
      require_acceptance = false

      tags = {
        domain = "security"
      }
    }
  }
}

# AWS Network Firewall resources (and routing)
module "sydney_inspection" {
  source    = "./modules/inspection"
  providers = { aws = aws.awssydney }

  identifier          = var.identifier
  vpc                 = module.sydney_inspection_vpc
  number_azs          = var.sydney_inspection_vpc.number_azs
  network_cidr_blocks = ["10.0.0.0/8"]
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
  aws_region  = var.aws_regions.sydney
}