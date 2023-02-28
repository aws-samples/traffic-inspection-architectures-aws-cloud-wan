<!-- BEGIN_TF_DOCS -->
# East/West traffic, with both Spoke VPCs and Inspection VPCs attached to AWS Cloud WAN

![East-West](../../images/east\_west.png)

## Prerequisites
- An AWS account with an IAM user with the appropriate permissions
- Terraform installed

## Code Principles:
- Writing DRY (Do No Repeat Yourself) code using a modular design pattern

## Usage
- Clone the repository
- (Optional) Edit the variables.tf file in the project root directory - if you want to test with different parameters.
- Deploy first the Global Network, Core Network, and Policy document attachment by using `terraform apply -target="aws_networkmanager_global_network.global_network" -target="aws_networkmanager_core_network.core_network" -target="aws_networkmanager_core_network_policy_attachment.core_network_policy_attachment"`
- Deploy the rest of the resources using `terraform apply`.
- Uncomment lines 113 - 137 in *cloud\_wan\_poliy.tf* file to create the static routes in the Core Network.
- Deploy the updated policy using `terraform apply`.
- Remember to clean up resoures once you are done by using `terraform destroy`.

**Note** EC2 instances, VPC endpoints, and AWS Network Firewall endpoints will be deployed in all the Availability Zones configured for each VPC. Keep this in mind when testing this environment from a cost perspective - for production environments, we recommend the use of at least 2 AZs for high-availability.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.46.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.46.0 |
| <a name="provider_aws.awsnvirginia"></a> [aws.awsnvirginia](#provider\_aws.awsnvirginia) | >= 4.46.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_iam"></a> [iam](#module\_iam) | ../modules/iam | n/a |
| <a name="module_ireland_compute"></a> [ireland\_compute](#module\_ireland\_compute) | ../modules/compute | n/a |
| <a name="module_ireland_endpoints"></a> [ireland\_endpoints](#module\_ireland\_endpoints) | ../modules/endpoints | n/a |
| <a name="module_ireland_inspection"></a> [ireland\_inspection](#module\_ireland\_inspection) | ./modules/inspection | n/a |
| <a name="module_ireland_inspection_vpc"></a> [ireland\_inspection\_vpc](#module\_ireland\_inspection\_vpc) | aws-ia/vpc/aws | = 4.0.0 |
| <a name="module_ireland_spoke_vpcs"></a> [ireland\_spoke\_vpcs](#module\_ireland\_spoke\_vpcs) | aws-ia/vpc/aws | = 4.0.0 |
| <a name="module_nvirginia_compute"></a> [nvirginia\_compute](#module\_nvirginia\_compute) | ../modules/compute | n/a |
| <a name="module_nvirginia_endpoints"></a> [nvirginia\_endpoints](#module\_nvirginia\_endpoints) | ../modules/endpoints | n/a |
| <a name="module_nvirginia_inspection"></a> [nvirginia\_inspection](#module\_nvirginia\_inspection) | ./modules/inspection | n/a |
| <a name="module_nvirginia_inspection_vpc"></a> [nvirginia\_inspection\_vpc](#module\_nvirginia\_inspection\_vpc) | aws-ia/vpc/aws | = 4.0.0 |
| <a name="module_nvirginia_spoke_vpcs"></a> [nvirginia\_spoke\_vpcs](#module\_nvirginia\_spoke\_vpcs) | aws-ia/vpc/aws | = 4.0.0 |
| <a name="module_sydney_compute"></a> [sydney\_compute](#module\_sydney\_compute) | ../modules/compute | n/a |
| <a name="module_sydney_endpoints"></a> [sydney\_endpoints](#module\_sydney\_endpoints) | ../modules/endpoints | n/a |
| <a name="module_sydney_inspection"></a> [sydney\_inspection](#module\_sydney\_inspection) | ./modules/inspection | n/a |
| <a name="module_sydney_inspection_vpc"></a> [sydney\_inspection\_vpc](#module\_sydney\_inspection\_vpc) | aws-ia/vpc/aws | = 4.0.0 |
| <a name="module_sydney_spoke_vpcs"></a> [sydney\_spoke\_vpcs](#module\_sydney\_spoke\_vpcs) | aws-ia/vpc/aws | = 4.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_networkmanager_core_network.core_network](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkmanager_core_network) | resource |
| [aws_networkmanager_core_network_policy_attachment.core_network_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkmanager_core_network_policy_attachment) | resource |
| [aws_networkmanager_global_network.global_network](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkmanager_global_network) | resource |
| [aws_networkmanager_core_network_policy_document.core_network_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/networkmanager_core_network_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_regions"></a> [aws\_regions](#input\_aws\_regions) | AWS Regions to create the environment. | `map(string)` | <pre>{<br>  "ireland": "eu-west-1",<br>  "nvirginia": "us-east-1",<br>  "sydney": "ap-southeast-2"<br>}</pre> | no |
| <a name="input_identifier"></a> [identifier](#input\_identifier) | Project Identifier, used as identifer when creating resources. | `string` | `"east-west"` | no |
| <a name="input_ireland_inspection_vpc"></a> [ireland\_inspection\_vpc](#input\_ireland\_inspection\_vpc) | Information about the Inspection VPC to create in eu-west-1. | `any` | <pre>{<br>  "cidr_block": "10.100.0.0/16",<br>  "cnetwork_subnet_netmask": 28,<br>  "flow_log_config": {<br>    "log_destination_type": "cloud-watch-logs",<br>    "retention_in_days": 7<br>  },<br>  "inspection_subnet_netmask": 28,<br>  "name": "inspection-eu-west-1",<br>  "number_azs": 2<br>}</pre> | no |
| <a name="input_ireland_spoke_vpcs"></a> [ireland\_spoke\_vpcs](#input\_ireland\_spoke\_vpcs) | Information about the VPCs to create in eu-west-1. | `any` | <pre>{<br>  "dev": {<br>    "cidr_block": "10.0.1.0/24",<br>    "cnetwork_subnet_netmask": 28,<br>    "endpoint_subnet_netmask": 28,<br>    "flow_log_config": {<br>      "log_destination_type": "cloud-watch-logs",<br>      "retention_in_days": 7<br>    },<br>    "instance_type": "t2.micro",<br>    "name": "dev-eu-west-1",<br>    "number_azs": 2,<br>    "segment": "dev",<br>    "workload_subnet_netmask": 28<br>  },<br>  "prod": {<br>    "cidr_block": "10.0.0.0/24",<br>    "cnetwork_subnet_netmask": 28,<br>    "endpoint_subnet_netmask": 28,<br>    "flow_log_config": {<br>      "log_destination_type": "cloud-watch-logs",<br>      "retention_in_days": 7<br>    },<br>    "instance_type": "t2.micro",<br>    "name": "prod-eu-west-1",<br>    "number_azs": 2,<br>    "segment": "prod",<br>    "workload_subnet_netmask": 28<br>  }<br>}</pre> | no |
| <a name="input_nvirginia_inspection_vpc"></a> [nvirginia\_inspection\_vpc](#input\_nvirginia\_inspection\_vpc) | Information about the Inspection VPC to create in us-east-1. | `any` | <pre>{<br>  "cidr_block": "10.100.0.0/16",<br>  "cnetwork_subnet_netmask": 28,<br>  "flow_log_config": {<br>    "log_destination_type": "cloud-watch-logs",<br>    "retention_in_days": 7<br>  },<br>  "inspection_subnet_netmask": 28,<br>  "name": "inspection-us-east-1",<br>  "number_azs": 2<br>}</pre> | no |
| <a name="input_nvirginia_spoke_vpcs"></a> [nvirginia\_spoke\_vpcs](#input\_nvirginia\_spoke\_vpcs) | Information about the VPCs to create in us-east-1. | `any` | <pre>{<br>  "dev": {<br>    "cidr_block": "10.10.1.0/24",<br>    "cnetwork_subnet_netmask": 28,<br>    "endpoint_subnet_netmask": 28,<br>    "flow_log_config": {<br>      "log_destination_type": "cloud-watch-logs",<br>      "retention_in_days": 7<br>    },<br>    "instance_type": "t2.micro",<br>    "name": "dev-us-east-1",<br>    "number_azs": 2,<br>    "segment": "dev",<br>    "workload_subnet_netmask": 28<br>  },<br>  "prod": {<br>    "cidr_block": "10.10.0.0/24",<br>    "cnetwork_subnet_netmask": 28,<br>    "endpoint_subnet_netmask": 28,<br>    "flow_log_config": {<br>      "log_destination_type": "cloud-watch-logs",<br>      "retention_in_days": 7<br>    },<br>    "instance_type": "t2.micro",<br>    "name": "prod-us-east-1",<br>    "number_azs": 2,<br>    "segment": "prod",<br>    "workload_subnet_netmask": 28<br>  }<br>}</pre> | no |
| <a name="input_segment_configuration"></a> [segment\_configuration](#input\_segment\_configuration) | Core Network Segment configuration. | `string` | `"default"` | no |
| <a name="input_sydney_inspection_vpc"></a> [sydney\_inspection\_vpc](#input\_sydney\_inspection\_vpc) | Information about the Inspection VPC to create in ap-southeast-2. | `any` | <pre>{<br>  "cidr_block": "10.100.0.0/16",<br>  "cnetwork_subnet_netmask": 28,<br>  "flow_log_config": {<br>    "log_destination_type": "cloud-watch-logs",<br>    "retention_in_days": 7<br>  },<br>  "inspection_subnet_netmask": 28,<br>  "name": "insp-ap-southeast-2",<br>  "number_azs": 2<br>}</pre> | no |
| <a name="input_sydney_spoke_vpcs"></a> [sydney\_spoke\_vpcs](#input\_sydney\_spoke\_vpcs) | Information about the VPCs to create in ap-southeast-2. | `any` | <pre>{<br>  "dev": {<br>    "cidr_block": "10.20.1.0/24",<br>    "cnetwork_subnet_netmask": 28,<br>    "endpoint_subnet_netmask": 28,<br>    "flow_log_config": {<br>      "log_destination_type": "cloud-watch-logs",<br>      "retention_in_days": 7<br>    },<br>    "instance_type": "t2.micro",<br>    "name": "dev-ap-southeast-2",<br>    "number_azs": 2,<br>    "segment": "dev",<br>    "workload_subnet_netmask": 28<br>  },<br>  "prod": {<br>    "cidr_block": "10.20.0.0/24",<br>    "cnetwork_subnet_netmask": 28,<br>    "endpoint_subnet_netmask": 28,<br>    "flow_log_config": {<br>      "log_destination_type": "cloud-watch-logs",<br>      "retention_in_days": 7<br>    },<br>    "instance_type": "t2.micro",<br>    "name": "prod-ap-southeast-2",<br>    "number_azs": 2,<br>    "segment": "prod",<br>    "workload_subnet_netmask": 28<br>  }<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloud_wan"></a> [cloud\_wan](#output\_cloud\_wan) | AWS Cloud WAN resources. |
| <a name="output_vpcs"></a> [vpcs](#output\_vpcs) | VPCs created. |
<!-- END_TF_DOCS -->