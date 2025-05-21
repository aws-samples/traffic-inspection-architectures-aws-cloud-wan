# East/West traffic, with Spoke VPCs attached to a peered AWS Transit Gateway (Single-hop inspection)

![East-West-SingleHop](../../../../images/east_west_tgw_spokeVpcs_singlehop.png)

## Prerequisites
- An AWS account with an IAM user with the appropriate permissions

## Usage
- Clone the repository
- (Optional) Edit the VPC CIDRs in the `east_west_tgw_spokevpcs_singlehop.yaml` file if you want to test with other values.
- You will find three files creating Core Network policy documents.
    - `base_policy.yaml` is used to create the resources without the Service Insertion actions. This is done because a Service Insertion action cannot reference a Network Function Group that has to attachments associated.
    - `core_network.yaml` contains the final format of the policy document, with the Service Insertion actions.
- Deploy the resources using `make deploy`.
- Remember to clean up resoures once you are done by using `make undeploy`.

**Note** EC2 instances, VPC endpoints, and AWS Network Firewall endpoints will be deployed in all the Availability Zones configured for each VPC. Keep this in mind when testing this environment from a cost perspective - for production environments, we recommend the use of at least 2 AZs for high-availability.
