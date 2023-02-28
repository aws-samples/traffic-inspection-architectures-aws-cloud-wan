# Traffic Inspection Architectures with AWS Cloud WAN - Terraform

This repository contains Terraform code to deploy several inspection architectures using AWS Cloud WAN - with AWS Network Firewall as inspection solution. The use cases covered are the following ones:

* [Centralized Outbound](./centralized_outbound/).
* [East/West traffic, with both Spoke VPCs and Inspection VPCs attached to AWS Cloud WAN](./east_west/).
* [East/West traffic, with both Spoke VPCs and Inspection VPCs attached to AWS Transit Gateway and peered with AWS Cloud WAN](./east_west_tgw/).
* [East/West traffic, with Spoke VPCs attached to a peered AWS Transit Gateway and Inspection VPCs attached to AWS Cloud WAN](./east_west_tgw_spoke_vpcs/).

In all the examples we are deploying resources in three AWS Regions: N. Virginia (us-east-1), Ireland (eu-west-1), and Sydney (ap-southeast-2)