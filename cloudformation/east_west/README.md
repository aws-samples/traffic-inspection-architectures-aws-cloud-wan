# East/West traffic, with both Spoke VPCs and Inspection VPCs attached to AWS Cloud WAN

## Multi-Region Dual-hop inspection (both AWS Regions)

![East-West](../../images/east_west_dualhop.png)

## Multi-Region Single-hop inspection (single AWS Regions)

In the example in this repository, the following matrix is used to determine which inspection VPC is used for traffic inspection:

| *AWS Region*       | us-east-1 | eu-west-1 | ap-southeast-2 |
| --------------     |:---------:| ---------:| --------------:|
| **us-east-1**      | us-east-1 | us-east-1 | us-east-1      |
| **eu-west-1**      | us-east-1 | eu-west-1 | eu-west-1      |
| **ap-southeast-2** | us-east-1 | eu-west-1 | ap-southeast-2 |

![East-West-SingleHop](../../images/east_west_singlehop.png)

## Prerequisites
- An AWS account with an IAM user with the appropriate permissions

## Usage
- Clone the repository
- (Optional) Edit the VPC CIDRs in the `east_west.yaml` file if you want to test with other values.
- You will find three files creating Core Network policy documents.
    - `base_policy.yaml` is used to create the resources without the Service Insertion actions. This is done because a Service Insertion action cannot reference a Network Function Group that has to attachments associated.
    - `core_network_dualhop.yaml` contains the final format of the policy document, with the Service Insertion actions.
    - If you want to see the single-hop behaviour, change line 3 in the *Makefile* to use the `core_network_singlehop.yaml` file.
- Deploy the resources using `make deploy`.
- Remember to clean up resoures once you are done by using `make undeploy`.

**Note** EC2 instances, VPC endpoints, and AWS Network Firewall endpoints will be deployed in all the Availability Zones configured for each VPC. Keep this in mind when testing this environment from a cost perspective - for production environments, we recommend the use of at least 2 AZs for high-availability.
