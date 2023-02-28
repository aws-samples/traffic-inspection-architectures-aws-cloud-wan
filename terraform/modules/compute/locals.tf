/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- module/compute/locals.tf ---

locals {
  instance_sg = {
    name        = "instance_security_group"
    description = "Instance SG (Allowing ICMP and HTTP/HTTPS access)"
    ingress = {
      http = {
        description = "Allowing HTTP traffic"
        from        = 80
        to          = 80
        protocol    = "tcp"
        cidr_blocks = [var.ingress_vpc_cidr]
      }
      icmp = {
        description = "Allowing ICMP traffic"
        from        = -1
        to          = -1
        protocol    = "icmp"
        cidr_blocks = ["10.0.0.0/8"]
      }
    }
    egress = {
      any = {
        description = "Any traffic"
        from        = 0
        to          = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
    }
  }
}
