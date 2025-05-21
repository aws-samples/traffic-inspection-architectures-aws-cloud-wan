# AWS Cloud WAN Blueprints

Welcome to the AWS Cloud WAN Blueprints!

This project offers a practical guidance for deploying [AWS Cloud WAN](https://aws.amazon.com/cloud-wan/), featuring real-world examples and full end-to-end deployment code. These blueprints complement AWS documentation and AWS blogs by expanding on concepts with complete implementations in various Infrastructure and Code (IaC) languages.

Designed for Level 400 (expert) users, the blueprints assume a solid understanding of AWS networking, including VPCs, subnets, route tables, Transit Gateways, and Direct Connect, as well as general networking concepts like IP addressing, routing, IPSec, GRE, BGP, VRFs, SD-WAN, and network security.

The guide covers advanced architectures, including integrating SD-WAN with AWS Cloud WAN, implementing multi-region inspection, extending VRFs, centralising internet egress with inspection, intra and inter segment inspection, and supporting multi-tenancy, particularly for Internet Service Providers and Telecommunications organisations.

## Table of Content

- [Consumption](#consumption)
- [Patterns](#patterns)
- [AWS Cloud WAN components and features](#aws-cloud-wan-components-and-features)
  - [Control Plane, AWS Network Manager, and Network Policy](#control-plane-aws-network-manager-and-the-network-policy)
  - [Core Network Edge (CNE)](#core-network-edge-cne)
  - [Segments](#segments)
  - [Routing actions](#routing-actions)
  - [Attachments](#attachments)
  - [Attachment policies](#attachment-policies)
- [FAQ](#faq)
- [Authors](#authors)
- [Contributing](#contributing)
- [License](#license)

## Consumption

These blueprints have been designed to be consumed in the following manners:

* **Reference Architecture**. You can use the examples and patterns provided as a guide to build your target architecture. From the architectures (and code provided) to can review and test the specific architecture and use it as reference to replicate in your environment.
* **Copy & paste**. You can do a quick copy-and-paste of a specific architecture snippet into your own environment, using the blueprints as the starting point for your implementation. You can then adapt the initial pattern to customize it to your specific needs. Of course, we recommend to deploy first in pre-production and have a controlled rollout to production environments after enough testing. 

**The Cloud WAN blueprints are not intended to be consumed as-is directly from this project**. The patterns provided will use local varibles (as defaults or required to be provided by you) that we recommend you change when deploying in your pre-production or testing environments.

## Patterns

1. Simple architectures (TBD)
2. [Traffic inspection architectures](./patterns/2-traffic_inspection/)
3. Hybrid architectures (TBD)

## AWS Cloud WAN components and features

[AWS Cloud WAN](https://docs.aws.amazon.com/network-manager/latest/cloudwan/what-is-cloudwan.html) is a managed, intent-driven service for building and managing global networks across [AWS Regions](https://aws.amazon.com/about-aws/global-infrastructure/regions_az/) and on-premises environments. Unlike traditional methods that require manual interconnection of multiple [AWS Transit Gateways](https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html) using regional route tables and static routing between Transit Gateway peering attachments, Cloud WAN automates networking including cross-region dynamic routing, network segmentation, and configuration management, streamlining global network operations.

With Cloud WAN, we have seen customers simplify networking complexities while enabling advanced routing, segmentation, and seamless integration with existing infrastructure. This project delves AWS Cloud WAN’s capabilities, configuration approaches, and advanced routing, helping you build and optimise global networking architectures.

### Control Plane, AWS Network Manager, and Network Policy

Cloud WAN is managed within AWS Network Manager, providing centralized management and visualization of global networks. The control plane is deployed within the Oregon (us-west-2) region i.e. where service is managed from and the metadata is stored.

The foundation of Cloud WAN is the [network policy](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-create-policy-version.html), written in a declarative language using JSON (JavaScript Object Notation) that defines all components of Cloud WAN, such as segments, routing, and how attachments map to segments. This policy-driven approach allows organizations to define their intent for access control and traffic routing, while Cloud WAN automates the underlying network configuration, ensuring scalability and consistency across Regions.

### Core Network Edge (CNE)

The Core Network Edge (CNE) is a key architectural component of Cloud WAN, acting as a regional router similar to a Transit Gateway. While it appears as a single entity within a region, it is highly available and resilient behind the scenes. The CNE is a data plane construct and can be deployed in any region where Cloud WAN is supported.

A key distinction between CNEs and Transit Gateways is that CNEs automatically establish full-mesh peering with one another, leveraging dynamic routing (e-BGP) to exchange routing information. This enables seamless, resilient, and optimal routing across all attached networks. In contrast, Transit Gateways require manual peering and rely on static routing for inter-region connectivity. A CNE supports up to 100Gbps throughput.

### Segments

A segment functions as a global route table (thinking on Transit Gateway terms). In traditional networking terms, a segment can be compared to a Virtual Routing and Forwarding (VRF) domain. While segments are available in every region where a Core Network Edge exists, you can limit the segment to specific Regions. Important to mention that any supported attachments can only be attached to a segment if it exists within its local Region.

How segments are defined depends entirely on customer requirements, but the most common patterns include:

1. Segmentation by **environment** (e.g., development, test, staging, production, hybrid)
2. Segmentation by **Business Unit** (e.g. Org A, Org B, Org C)
3. Segmentation by **continent** (e.g., North America, Latin America, Europe, Asia Pacific)

Customers may also use a combination of these patterns or a different pattern altogether, but it is important to note that Cloud WAN supports a maximum of 40 segments.

By default, when an attachment is associated with a segment, it automatically propagates its prefixes to that segment, allowing intra-segment traffic by default. While segments share similarities with VRFs, there are key differences:

* Segments can contain Isolated or Non-Isolated attachments. Isolated attachments override the next-hop for a propagated prefix, routing traffic for inspection rather than direct forwarding. More details on this can be found in the [Service Insertion](#service-insertion) section. If you do not create a service insertion, the prefixes will not propagate into the segment, despite being attached to the segment.
* Overlapping (identical) prefixes cannot be propagated into a segment. If attempted, Cloud WAN will only propagate the first prefix, following a *first one wins* rule.

### Routing actions

#### Segment sharing

A **share** action in Cloud WAN is the exchange (propagation) of routes between segments (in a 1:1 fashion or 1:many), without requiring inspection. Important to note that segments are non-transitive, i.e. you cannot route between two segments if a share action has not been created - only learned routes that are directly attached to the segment are exchanged.

#### Service Insertion

The service insertion mechanism defines how inspection is performed, supporting:

* Intra-segment traffic - for *isolated* segments.
* Inter-segment traffic.
* Egress traffic.

To start defining Service Insertion we need to start by indicating how to include the firewalls in the network. The integration works the same as with Transit Gateway: by attaching an Inspection VPC to the network. However, there are some changes in how the inspection routing configuration works.

To start, Inspection VPCs are associated to [Network Function Groups](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-network-function-groups.html) (NFGs). A NFG acts as a container for attachments hosting security functions and can be thought of as a managed security segment. Like segments, NFGs are global constructs and can be associated with multiple Inspection VPCs, supporting cross-region inspection to ensure consistent security enforcement across a global network. You can have one or many Network Function Groups, depending on how your firewalls are grouped. 

To allow inspection, you have two different actions to configure in Cloud WAN:

* "send-via" for east-west traffic (intra or inter-segment) inspection.
* "send-to" for egress traffic inspection.

### Attachments

A Cloud WAN attachment is a connection between a network resource (such as a VPC, AWS Direct Connect gateway, SD-WAN Overlay, or a Site-to-Site VPN) and a CNE within AWS Cloud WAN. An attachment can only be associated with one segment. There are a number of different attachment types supported in Cloud WAN:

1. VPC – Connect a VPC to Cloud WAN, allowing instances within the VPC to communicate with other network segments.
2. Site-to-Site VPN – Connect on-premises networks to Cloud WAN using an IPsec VPN tunnel.
3. Direct Connect Gateway – Connect on-premise networks to Cloud WAN using an AWS Direct Connect.
4. Transit Gateway Route Table – Connect an existing AWS Transit Gateway (TGW) to Cloud WAN for seamless integration.
5. Connect - Connect to third-party SD-WAN appliances using high-performance attachments providing seamless connectivity. 
    1. GRE (Generic Routing Encapsulation).
    2. Tunnel-less Connect (No Encapsulation).

**Note**: A Connect Attachment is used for overlay networking to integrate with SD-WAN appliances. However, it still requires an underlay (transport) VPC attachment.

### Attachment Policies

Attachment Policies are rules within Cloud WAN that govern how attachments are associated with segments or NGFs in a core network. A number of attributes are supper such as tags, attachment type, AWS Account ID, or AWS Region. For NFG association, only tags are supported.

By default, segments and NFGs will auto-accept attachment requests, but this can be disabled by enabling the *require acceptance* feature. This will ensure that when an attachment is created and associated with a segment/NFG, an administrator must approve the association. Until this is done, the attachment remains in a pending state and will not be able to access the core network. The *require acceptance* feature is recommended for segments that contain sensitive workloads, especially where isolated attachments are not being used.

## FAQ

### I still see some patterns with a "TBD" description

We have already an idea of the general structure of the blueprints we want to cover in this project. However, we have just started developing them and it will take some time until we have a v1 ready. Having *placeholders* allow us to provide you the patterns we have ready while we work on the rest.

In addition, if you have any feedback on the current patterns, or do you want us to work in new patterns, see [CONTRIBUTING](./CONTRIBUTING.md) for more information.

### What are the bandwidth and MTU supported in AWS Cloud WAN?

For an updated information of quotas and limits in AWS Cloud WAN, please refer to the [documentation](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-quotas.html).

## Authors

* Mevlit Mustafa, Sr. Network Specialist Solutions Architect, AWS
* Pablo Sánchez Carmona, Sr. Network Specialist Solutions Architect, AWS

## Contributing

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

