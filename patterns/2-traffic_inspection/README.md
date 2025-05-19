
<!-- ## Use cases

In all use cases, you will find two routing domains: **production** and **development**. The inspection requirements are the following ones:

* VPC traffic within the **production** segment will be inspected.
* Inter-segment traffic will be inspected.
* VPCs within the **development** segment can talk between each other directly.

This repository does not focus on AWS Network Firewall's policy configuration, therefore the policy rules configured are simple and only used to test connectivity. 

* For egress traffic, only traffic to *.amazon.com* domains is allowed.
* For east-west traffic, any ICMP packets are alerted and allowed.

### Centralized Outbound

The Core Network's policy creates the following resources:

* 1 [segment](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-segments.html) per routing domain - *production* (isolated) and *development*. Core Network's policy includes an attachment policy rule that maps each spoke VPCs to the corresponding segment if the attachment contains the following tag: *domain={segment_name}*
* 1 [network function group](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-network-function-groups.html) (NFG) for the inspection VPCs. Core Network's policy includes an attachment policy rule that associates the inspection VPC to the NFG if the attachment includes the following tag: *inspection=true*.
* **Service Insertion rules**: in each routing domain's segment, a [send-to](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-service-insertion.html#:~:text=insertion%2Denabled%20segment.-,Send%20to,-%E2%80%94%20Traffic%20flows%20north) action is created to send the default traffic (0.0.0.0/0 and ::/0) to the inspection VPCs.

![Centralized Outbound](./images/centralizedOutbound.png)

```json
{
    "version": "2021.12",
    "core-network-configuration": {
      "vpn-ecmp-support": true,
      "asn-ranges": [
        "64520-65525"
      ],
      "edge-locations": [
        {
          "location": "eu-west-1"
        },
        {
          "location": "us-east-1"
        },
        {
          "location": "ap-southeast-2"
        }
      ]
    },
    "segments": [
      {
        "name": "production",
        "require-attachment-acceptance": false,
        "isolate-attachments": true
      },
      {
        "name": "development",
        "require-attachment-acceptance": false
      }
    ],
    "network-function-groups": [
      {
        "name": "inspectionVpcs",
        "require-attachment-acceptance": false
      }
    ],
    "segment-actions": [
      {
        "action": "send-to",
        "segment": "production",
        "via": {
          "network-function-groups": [
            "inspectionVpcs"
          ]
        }
      },
      {
        "action": "send-to",
        "segment": "development",
        "via": {
          "network-function-groups": [
            "inspectionVpcs"
          ]
        }
      }
    ],
    "attachment-policies": [
      {
        "rule-number": 100,
        "condition-logic": "or",
        "conditions": [
          {
            "type": "tag-value",
            "operator": "equals",
            "key": "inspection",
            "value": "true"
          }
        ],
        "action": {
            "add-to-network-function-group": "inspectionVpcs"
        }
      },
      {
        "rule-number": 200,
        "condition-logic": "or",
        "conditions": [
          {
            "type": "tag-exists",
            "key": "domain"
          }
        ],
        "action": {
          "association-method": "tag",
          "tag-value-of-key": "domain"
        }
      }
    ]
}
```

### Centralized Outbound (AWS Region without Inspection VPC)

This example is similar to the one above, with the difference that we add 1 AWS Region that does not have Inspection VPC. We take advantage of Cloud WAN's service insertion feature to make sure outbound traffic is inspected by the closest Region with Inspection VPC. In this example, London (eu-west-2) does not have Inspection VPC, and we want Ireland (eu-west-1) to  inspect outbound traffic from both Ireland and London.

The Core Network's policy creates the following resources:

* 1 [segment](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-segments.html) per routing domain - *production* (isolated) and *development*. Core Network's policy includes an attachment policy rule that maps each spoke VPCs to the corresponding segment if the attachment contains the following tag: *domain={segment_name}*
* 1 [network function group](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-network-function-groups.html) (NFG) for the inspection VPCs. Core Network's policy includes an attachment policy rule that associates the inspection VPC to the NFG if the attachment includes the following tag: *inspection=true*.
* **Service Insertion rules**: in each routing domain's segment, a [send-to](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-service-insertion.html#:~:text=insertion%2Denabled%20segment.-,Send%20to,-%E2%80%94%20Traffic%20flows%20north) action is created to send the default traffic (0.0.0.0/0 and ::/0) to the inspection VPCs.
  * A *with-edge-overrides* parameter is included to indicate that traffic from *eu-west-2* should be inspected by *eu-west-1* (given *eu-west-2* won't have a local Inspection VPC).

![Centralized Outbound](./images/centralizedOutbound_regionWithoutInspection.png)

```json
{
  "version": "2021.12",
  "core-network-configuration": {
    "vpn-ecmp-support": true,
    "asn-ranges": [
      "64520-65525"
    ],
    "edge-locations": [
      {
        "location": "eu-west-1"
      },
      {
        "location": "eu-west-2"
      },
      {
        "location": "us-east-1"
      },
      {
        "location": "ap-southeast-2"
      }
    ]
  },
  "segments": [
    {
      "name": "production",
      "require-attachment-acceptance": false,
      "isolate-attachments": true
    },
    {
      "name": "development",
      "require-attachment-acceptance": false
    }
  ],
  "network-function-groups": [
    {
      "name": "inspectionVpcs",
      "require-attachment-acceptance": false
    }
  ],
  "segment-actions": [
    {
      "action": "send-to",
      "segment": "production",
      "via": {
        "network-function-groups": [
          "inspectionVpcs"
        ],
        "with-edge-overrides": [
          {
            "edge-sets": [
              [
                "eu-west-2"
              ]
            ],
            "use-edge-location": "eu-west-1"
          }
        ]
      }
    },
    {
      "action": "send-to",
      "segment": "development",
      "via": {
        "network-function-groups": [
          "inspectionVpcs"
        ],
        "with-edge-overrides": [
          {
            "edge-sets": [
              [
                "eu-west-2"
              ]
            ],
            "use-edge-location": "eu-west-1"
          }
        ]
      }
    }
  ],
  "attachment-policies": [
    {
      "rule-number": 100,
      "condition-logic": "or",
      "conditions": [
        {
          "type": "tag-value",
          "operator": "equals",
          "key": "inspection",
          "value": "true"
        }
      ],
      "action": {
        "add-to-network-function-group": "inspectionVpcs"
      }
    },
    {
      "rule-number": 200,
      "condition-logic": "or",
      "conditions": [
        {
          "type": "tag-exists",
          "key": "domain"
        }
      ],
      "action": {
        "association-method": "tag",
        "tag-value-of-key": "domain"
      }
    }
  ]
}
```

### East/West traffic (Dual-hop)

The Core Network's policy creates the following resources:

* 1 [segment](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-segments.html) per routing domain - *production* (isolated) and *development*. Core Network's policy includes an attachment policy rule that maps each spoke VPCs to the corresponding segment if the attachment contains the following tag: *domain={segment_name}*
* 1 [network function group](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-network-function-groups.html) (NFG) for the inspection VPCs. Core Network's policy includes an attachment policy rule that associates the inspection VPC to the NFG if the attachment includes the following tag: *inspection=true*.
* **Service Insertion rules**: one [send-via](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-service-insertion.html#:~:text=north%2Dsouth%20traffic.-,Send%20via,-%E2%80%94%20Traffic%20flows%20east) action to inspect the traffic between VPCs in the *production* segment, and between the *production* and *development* segments. The mode used is *dual-hop*, meaning that traffic traversing two AWS Regions is inspected in both of them.

![East-West](./images/east_west_dualhop.png)
  
```json
{
    "version": "2021.12",
    "core-network-configuration": {
      "vpn-ecmp-support": true,
      "asn-ranges": [
        "64520-65525"
      ],
      "edge-locations": [
        {
          "location": "eu-west-1"
        },
        {
          "location": "us-east-1"
        },
        {
          "location": "ap-southeast-2"
        }
      ]
    },
    "segments": [
      {
        "name": "production",
        "require-attachment-acceptance": false,
        "isolate-attachments": true
      },
      {
        "name": "development",
        "require-attachment-acceptance": false
      }
    ],
    "network-function-groups": [
      {
        "name": "inspectionVpcs",
        "require-attachment-acceptance": false
      }
    ],
    "segment-actions": [
      {
        "action": "send-via",
        "segment": "production",
        "mode": "dual-hop",
        "when-sent-to": {
          "segments": "*"
        },
        "via": {
          "network-function-groups": [
            "inspectionVpcs"
          ]
        }
      }
    ],
    "attachment-policies": [
      {
        "rule-number": 100,
        "condition-logic": "or",
        "conditions": [
          {
            "type": "tag-value",
            "operator": "equals",
            "key": "inspection",
            "value": "true"
          }
        ],
        "action": {
            "add-to-network-function-group": "inspectionVpcs"
        }
      },
      {
        "rule-number": 200,
        "condition-logic": "or",
        "conditions": [
          {
            "type": "tag-exists",
            "key": "domain"
          }
        ],
        "action": {
          "association-method": "tag",
          "tag-value-of-key": "domain"
        }
      }
    ]
}
```

### East/West traffic (Single-hop)

The Core Network's policy creates the following resources:

* 1 [segment](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-segments.html) per routing domain - *production* (isolated) and *development*. Core Network's policy includes an attachment policy rule that maps each spoke VPCs to the corresponding segment if the attachment contains the following tag: *domain={segment_name}*
* 1 [network function group](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-network-function-groups.html) (NFG) for the inspection VPCs. Core Network's policy includes an attachment policy rule that associates the inspection VPC to the NFG if the attachment includes the following tag: *inspection=true*.
* **Service Insertion rules**: one [send-via](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-service-insertion.html#:~:text=north%2Dsouth%20traffic.-,Send%20via,-%E2%80%94%20Traffic%20flows%20east) action to inspect the traffic between VPCs in the *production* segment, and between the *production* and *development* segments. 
  * The mode used is *single-hop*, meaning that traffic traversing two AWS Regions is inspected in only one of them.
  * In addition, one of the Regions (*eu-west-2* in the example) does not have local Inspection VPC. With *single-hop* mode, the traffic from this Region to other ones is inspected in the Region with a local Inspection VPC. For inspection between segments within the Region, *eu-west-1* is used.

The following matrix is used to determine which Inspection VPC is used for traffic inspection:

| *AWS Region*       | us-east-1 | eu-west-1 | eu-west-2      | ap-south-east-2 |
| --------------     |:---------:| ---------:| --------------:| ---------------:|
| **us-east-1**      | us-east-1 | us-east-1 | us-east-1      | us-east-1       |
| **eu-west-1**      | us-east-1 | eu-west-1 | eu-west-1      | eu-west-1       | 
| **eu-west-2**      | us-east-1 | eu-west-1 | eu-west-1      | ap-southeast-2  |
| **ap-southeast-2** | us-east-1 | eu-west-1 | ap-southeast-2 | ap-southeast-2  |

![East-West-SingleHop](./images/east_west_singlehop.png)

```json
{
    "version": "2021.12",
    "core-network-configuration": {
      "vpn-ecmp-support": true,
      "asn-ranges": [
        "64520-65525"
      ],
      "edge-locations": [
        {
          "location": "eu-west-1"
        },
        {
          "location": "eu-west-2"
        },
        {
          "location": "us-east-1"
        },
        {
          "location": "ap-southeast-2"
        }
      ]
    },
    "segments": [
      {
        "name": "production",
        "require-attachment-acceptance": false,
        "isolate-attachments": true
      },
      {
        "name": "development",
        "require-attachment-acceptance": false
      }
    ],
    "network-function-groups": [
      {
        "name": "inspectionVpcs",
        "require-attachment-acceptance": false
      }
    ],
    "segment-actions": [
      {
        "action": "send-via",
        "segment": "production",
        "mode": "single-hop",
        "when-sent-to": {
          "segments": "*"
        },
        "via": {
          "network-function-groups": [
            "inspectionVpcs"
          ],
          "with-edge-overrides": [
            {
              "edge-sets": [
                [
                  "us-east-1",
                  "eu-west-1"
                ]
              ],
              "use-edge-location": "us-east-1"
            },
            {
              "edge-sets": [
                [
                  "us-east-1",
                  "ap-southeast-2"
                ]
              ],
              "use-edge-location": "us-east-1"
            },
            {
              "edge-sets": [
                [
                  "ap-southeast-2",
                  "eu-west-1"
                ]
              ],
              "use-edge-location": "eu-west-1"
            },
            {
              "edge-sets": [
                [
                  "eu-west-2",
                  "eu-west-1"
                ]
              ],
              "use-edge-location": "eu-west-1"
            },
            {
              "edge-sets": [
                [
                  "eu-west-2",
                  "us-east-1"
                ]
              ],
              "use-edge-location": "us-east-1"
            },
            {
              "edge-sets": [
                [
                  "ap-southeast-2",
                  "eu-west-2"
                ]
              ],
              "use-edge-location": "ap-southeast-2"
            },
            {
              "edge-sets": [
                [
                  "eu-west-2"
                ]
              ],
              "use-edge-location": "eu-west-1"
            }
          ]
        }
      }
    ],
    "attachment-policies": [
      {
        "rule-number": 100,
        "condition-logic": "or",
        "conditions": [
          {
            "type": "tag-value",
            "operator": "equals",
            "key": "inspection",
            "value": "true"
          }
        ],
        "action": {
            "add-to-network-function-group": "inspectionVpcs"
        }
      },
      {
        "rule-number": 200,
        "condition-logic": "or",
        "conditions": [
          {
            "type": "tag-exists",
            "key": "domain"
          }
        ],
        "action": {
          "association-method": "tag",
          "tag-value-of-key": "domain"
        }
      }
    ]
}
```

### East/West traffic (Dual-hop). Spoke VPCs attached to AWS Transit Gateway

In this use case, you have two sets of Inspection VPCs: the ones attached to AWS Cloud WAN are used for inter-Region traffic, while the ones attached to AWS Transit Gateway are used for intra-Region traffic.

* If you are using AWS Network Firewall as firewall solution, the use of different Inspection VPCs means duplicating the firewall resources. 
  * If you don't want this duplication of resources (extra cost or managament), you can also have only 1 Inspection VPC attached to both Cloud WAN and Transit Gateway. This pattern will require more specific route when configuring the VPC routes pointing back to the network - *local* routes via Transit Gateway, *cross-Region* routes to Cloud WAN.
* If you are using another firewall solution behind [Gateway Load Balancer](https://aws.amazon.com/elasticloadbalancing/gateway-load-balancer/) (GWLB), you can place GWLB endpoints in several VPCs pointing to the same GWLB. This means that, although you have two different VPCs to simplify the routing, you are not duplicating the number of firewall resources.

The following resources are created:

* In each AWS Region, the spoke VPCs are attached to a Transit Gateway. Four TGW route tables are created:
  * The spoke VPCs of the production routing domain are associated to the *production* route table.
  * The spoke VPCs of the development routing domain are associated and propagate their routes to the *development* route table.
  * A third route table (*prod_routes*) is created to inject the production spoke VPCs to Cloud WAN. This enables Cloud WAN to learn the production VPCs CIDRs to create the corresponding routes when configuring the Service Insertion *send-via* actions.
  * The Inspection VPC attachment to the Transit Gateway is associated to a fourth route table (*post_inspection*), for the delivery of the intra-Region inspected traffic.
* Each Transit Gateway is peered with Cloud WAN.
* Two static routes (0.0.0.0/0 & ::/0) in both the *production* and *development* TGW route tables pointing to the Inspection VPC TGW attachment, to enable intra-Region inspection. You can also use more specific routing (either a supernet or a [managed prefix list](https://docs.aws.amazon.com/vpc/latest/userguide/managed-prefix-lists.html) containing all the VPC CIDRs in the Region)
* The Cloud WAN policy configures the following:
  * 1 [segment](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-segments.html) per routing domain - *production* (isolated) and *development*. Core Network's policy includes an attachment policy rule that associates each Transit Gateway route table attachment to the corresponding segment if the attachment contains the following tag: *domain={segment_name}*. In the example, the *production* and *prod_routes* TGW route table are associated to the *production* segment, and the *development* route table is associated to the *development* segment.
  * 1 [network function group](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-network-function-groups.html) (NFG) for the inspection VPCs. Core Network's policy includes an attachment policy rule that associates the inspection VPC to the NFG if the attachment includes the following tag: *inspection=true*.
  * **Service Insertion rules**: 
    * Two [send-via](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-service-insertion.html#:~:text=north%2Dsouth%20traffic.-,Send%20via,-%E2%80%94%20Traffic%20flows%20east) actions to inspect the traffic between VPCs in the *production* segment, and between the *production* and *development* segments.
    * With the send-via action, you will see in the TGWs a path to connect VPCs within the same routing domain (*production* via inspection, *development* direct path) and within different routing domains in different Regions (via inspection). However, routes between segments in the same Region (via inspection) won't be propagated. **That's why we need a dedicated Inspection VPC attached to the Transit Gateway to enable intra-Region traffic.**

![East-West-DualHop](./images/east_west_tgw_spokeVpcs_dualhop.png)

```json
{
  "version": "2021.12",
  "core-network-configuration": {
    "asn-ranges": [
      "64520-65525"
    ],
    "edge-locations": [
      {
        "location": "eu-west-1"
      },
      {
        "location": "us-east-1"
      },
      {
        "location": "ap-southeast-2"
      }
    ],
    "vpn-ecmp-support": false
  },
  "segments": [
    {
      "isolate-attachments": false,
      "name": "development",
      "require-attachment-acceptance": false
    },
    {
      "isolate-attachments": true,
      "name": "production",
      "require-attachment-acceptance": false
    }
  ],
  "network-function-groups": [
    {
      "name": "inspectionVpcs",
      "require-attachment-acceptance": false
    }
  ],
  "segment-actions": [
    {
      "action": "send-via",
      "mode": "dual-hop",
      "segment": "production",
      "via": {
        "network-function-groups": [
          "inspectionVpcs"
        ]
      },
      "when-sent-to": {
        "segments": [
          "development"
        ]
      }
    },
    {
      "action": "send-via",
      "mode": "dual-hop",
      "segment": "production",
      "via": {
        "network-function-groups": [
          "inspectionVpcs"
        ]
      },
      "when-sent-to": {
        "segments": "production"
      }
    }
  ],
  "attachment-policies": [
    {
      "action": {
        "add-to-network-function-group": "inspectionVpcs"
      },
      "condition-logic": "or",
      "conditions": [
        {
          "key": "inspection",
          "operator": "equals",
          "type": "tag-value",
          "value": "true"
        }
      ],
      "rule-number": 100
    },
    {
      "action": {
        "association-method": "tag",
        "tag-value-of-key": "domain"
      },
      "condition-logic": "or",
      "conditions": [
        {
          "key": "domain",
          "type": "tag-exists"
        }
      ],
      "rule-number": 200
    }
  ]
}
```

### East/West traffic (Single-hop). Spoke VPCs attached to AWS Transit Gateway

The following resources are created:

* In each AWS Region, the spoke VPCs are attached to a Transit Gateway. Three TGW route tables are created:
  * The spoke VPCs of the production routing domain are associated to the **production* route table.
  * The spoke VPCs of the development routing domain are associated and propagate their routes to the *development* route table.
  * A third route table (*prod_routes*) is created to inject the production spoke VPCs to Cloud WAN. This enables Cloud WAN to learn the production VPCs CIDRs to create the corresponding routes when configuring the Service Insertion actions.
* Each Transit Gateway is peered with Cloud WAN.
* The Cloud WAN policy configures the following:
  * 1 [segment](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-segments.html) per routing domain - *production* (isolated) and *development*. Core Network's policy includes an attachment policy rule that associates each Transit Gateway route table attachment to the corresponding segment if the attachment contains the following tag: *domain={segment_name}*. In the example, the *production* and *prod_routes* TGW route table are associated to the *production* segment, and the *development* route table is associated to the *development* segment.
  * 1 [network function group](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-network-function-groups.html) (NFG) for the inspection VPCs. Core Network's policy includes an attachment policy rule that associates the inspection VPC to the NFG if the attachment includes the following tag: *inspection=true*.
  * **Service Insertion rules**: 
    * One [send-via](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-service-insertion.html#:~:text=north%2Dsouth%20traffic.-,Send%20via,-%E2%80%94%20Traffic%20flows%20east) action to inspect the traffic between VPCs in the *production* segment, and between the *production* and *development* segments.
    * With only the send-via action, you will see in the TGWs a path to connect VPCs within the same routing domain (*production* via inspection, *development* direct path) and within different routing domains in different Regions (via inspection). However, routes between segments in the same Region (via inspection) won't be propagated.
    * To allow intra-Region communication, two [send-to](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policy-service-insertion.html#:~:text=insertion%2Denabled%20segment.-,Send%20to,-%E2%80%94%20Traffic%20flows%20north) actions are created to send the default traffic (0.0.0.0/0 and ::/0) to the inspection VPCs.

![East-West-SingleHop](./images/east_west_tgw_spokeVpcs_singlehop.png)

```json
{
  "version": "2021.12",
  "core-network-configuration": {
    "vpn-ecmp-support": true,
    "asn-ranges": [
      "64520-65525"
    ],
    "edge-locations": [
      {
        "location": "eu-west-1"
      },
      {
        "location": "us-east-1"
      },
      {
        "location": "ap-southeast-2"
      }
    ]
  },
  "segments": [
    {
      "name": "production",
      "require-attachment-acceptance": false,
      "isolate-attachments": true
    },
    {
      "name": "development",
      "require-attachment-acceptance": false
    }
  ],
  "network-function-groups": [
    {
      "name": "inspectionVpcs",
      "require-attachment-acceptance": false
    }
  ],
  "segment-actions": [
    {
      "action": "send-to",
      "segment": "production",
      "via": {
        "network-function-groups": [
          "inspectionVpcs"
        ]
      }
    },
    {
      "action": "send-to",
      "segment": "development",
      "via": {
        "network-function-groups": [
          "inspectionVpcs"
        ]
      }
    },
    {
      "action": "send-via",
      "segment": "production",
      "mode": "single-hop",
      "when-sent-to": {
        "segments": "*"
      },
      "via": {
        "network-function-groups": [
          "inspectionVpcs"
        ],
        "with-edge-overrides": [
          {
            "edge-sets": [
              [
                "us-east-1",
                "eu-west-1"
              ]
            ],
            "use-edge-location": "us-east-1"
          },
          {
            "edge-sets": [
              [
                "us-east-1",
                "ap-southeast-2"
              ]
            ],
            "use-edge-location": "us-east-1"
          },
          {
            "edge-sets": [
              [
                "ap-southeast-2",
                "eu-west-1"
              ]
            ],
            "use-edge-location": "eu-west-1"
          }
        ]
      }
    }
  ],
  "attachment-policies": [
    {
      "rule-number": 100,
      "condition-logic": "or",
      "conditions": [
        {
          "type": "tag-value",
          "operator": "equals",
          "key": "inspection",
          "value": "true"
        }
      ],
      "action": {
        "add-to-network-function-group": "inspectionVpcs"
      }
    },
    {
      "rule-number": 200,
      "condition-logic": "or",
      "conditions": [
        {
          "type": "tag-exists",
          "key": "domain"
        }
      ],
      "action": {
        "association-method": "tag",
        "tag-value-of-key": "domain"
      }
    }
  ]
}
``` -->
