/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- module/endpoints/locals.tf ---

locals {
  endpoint_sg = {
    name        = "endpoints_sg"
    description = "Security Group for SSM connection"
    ingress = {
      https = {
        description = "Allowing HTTPS"
        from        = 443
        to          = 443
        protocol    = "tcp"
        cidr_blocks = [var.vpc_cidr]
      }
    }
    egress = {
      any = {
        description = "Any traffic"
        from        = 0
        to          = 0
        protocol    = "-1"
        cidr_blocks = [var.vpc_cidr]
      }
    }
  }

  endpoint_service_names = {
    ssm = {
      name        = "com.amazonaws.${var.aws_region}.ssm"
      type        = "Interface"
      private_dns = true
    }
    ssmmessages = {
      name        = "com.amazonaws.${var.aws_region}.ssmmessages"
      type        = "Interface"
      private_dns = true
    }
    ec2messages = {
      name        = "com.amazonaws.${var.aws_region}.ec2messages"
      type        = "Interface"
      private_dns = true
    }
  }
}