/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- east_west_tgw_spoke_vpcs/modules/policy/firewall_policy.tf ---

resource "aws_networkfirewall_firewall_policy" "anfw_policy" {
  name = "firewall-policy-${var.identifier}"

  firewall_policy {
    # Stateless configuration
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateless_rule_group_reference {
      priority     = 10
      resource_arn = aws_networkfirewall_rule_group.drop_remote.arn
    }

    # Stateful configuration
    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }
    stateful_default_actions = ["aws:drop_strict", "aws:alert_strict"]
    stateful_rule_group_reference {
      priority     = 10
      resource_arn = aws_networkfirewall_rule_group.allow_icmp.arn
    }
  }
}

# Stateless Rule Group - Dropping any SSH or RDP connection
resource "aws_networkfirewall_rule_group" "drop_remote" {
  capacity = 2
  name     = "drop-remote-${var.identifier}"
  type     = "STATELESS"
  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {

        stateless_rule {
          priority = 1
          rule_definition {
            actions = ["aws:drop"]
            match_attributes {
              protocols = [6]
              source {
                address_definition = "0.0.0.0/0"
              }
              source_port {
                from_port = 22
                to_port   = 22
              }
              destination {
                address_definition = "0.0.0.0/0"
              }
              destination_port {
                from_port = 22
                to_port   = 22
              }
            }
          }
        }

        stateless_rule {
          priority = 2
          rule_definition {
            actions = ["aws:drop"]
            match_attributes {
              protocols = [27]
              source {
                address_definition = "0.0.0.0/0"
              }
              destination {
                address_definition = "0.0.0.0/0"
              }
            }
          }
        }
      }
    }
  }
}

# Stateful Rule Group - Allowing ICMP traffic
resource "aws_networkfirewall_rule_group" "allow_icmp" {
  capacity = 100
  name     = "allow-icmp-${var.identifier}"
  type     = "STATEFUL"
  rule_group {
    rule_variables {
      ip_sets {
        key = "PROD"
        ip_set {
          definition = ["10.0.0.0/24", "10.10.0.0/24", "10.20.0.0/24"]
        }
      }
      ip_sets {
        key = "DEV"
        ip_set {
          definition = ["10.0.1.0/24", "10.10.1.0/24", "10.20.1.0/24"]
        }
      }
    }
    rules_source {
      rules_string = <<EOF
      alert icmp any any -> any any (msg: "Alerting traffic passing through firewall"; sid:1; rev:1;)
      pass icmp any any -> any any (msg: "Allowing ICMP packets"; sid:2; rev:1;)
      EOF
    }
    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
  }
}