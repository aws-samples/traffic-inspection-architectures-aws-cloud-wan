/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- module/endpoints/main.tf ---

# VPC Endpoints Security Groups
resource "aws_security_group" "endpoints_sg" {
  name        = local.endpoint_sg.name
  description = local.endpoint_sg.description
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = local.endpoint_sg.ingress
    content {
      description = ingress.value.description
      from_port   = ingress.value.from
      to_port     = ingress.value.to
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = local.endpoint_sg.egress
    content {
      description = egress.value.description
      from_port   = egress.value.from
      to_port     = egress.value.to
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }

  tags = {
    Name = "${var.vpc_name}-endpoints-security-group-${var.identifier}"
  }
}

# VPC endpoints
resource "aws_vpc_endpoint" "endpoint" {
  for_each = local.endpoint_service_names

  vpc_id              = var.vpc_id
  service_name        = each.value.name
  vpc_endpoint_type   = each.value.type
  subnet_ids          = var.vpc_subnets
  security_group_ids  = [aws_security_group.endpoints_sg.id]
  private_dns_enabled = each.value.private_dns
}