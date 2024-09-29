# Traffic Inspection Architectures with AWS Cloud WAN - AWS CloudFormation

This repository contains AWS CloudFormation code to deploy several inspection architectures using AWS Cloud WAN - with AWS Network Firewall as inspection solution. The use cases covered are the following ones:

* [Centralized Outbound](./centralized_outbound/)
* [Centralized Outbound (AWS Region without Inspection)](./centralized_outbound_region_without_inspection/)
* [East/West traffic (Dual-hop inspection)](./east_west_dualhop/)
* [East/West traffic (Single-hop inspection)](./east_west_singlehop/)
* [East/West traffic - spoke VPCs attached to a peered AWS Transit Gateway](./east_west_tgw_spoke_vpcs/)

In all the examples we are deploying resources in three AWS Regions: N. Virginia (*us-east-1*), Ireland (*eu-west-1*), and Sydney (*ap-southeast-2*). In some examples (the ones where we show an AWS Region without Inspection VPC) we add London (*eu-west-2*) Region as well.