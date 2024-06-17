# Centralized Outbound inspection with AWS Cloud WAN

![Centralized Outbound](../../images/centralizedOutbound.png)

## Prerequisites
- An AWS account with an IAM user with the appropriate permissions

## Usage
- Clone the repository
- (Optional) Edit the VPC CIDRs in the `centralized_outbound.yaml` file if you want to test with other values.
- Deploy the resources using `make deploy`.
- Remember to clean up resoures once you are done by using `make undeploy`.
- You will find two documents defining a Core Network policy.
    - `base_policy.yaml` is used to create the resources without the Service Insertion actions. This is done because a Service Insertion action cannot reference a Network Function Group that has to attachments associated.
    - Once the initial version of the policy and resources are created, the `core_network.yaml` file is used to update the Core Network policy with the Service Insertion actions.

**Note** EC2 instances and AWS Network Firewall endpoints will be deployed in all the Availability Zones configured for each VPC. Keep this in mind when testing this environment from a cost perspective - for production environments, we recommend the use of at least 2 AZs for high-availability.