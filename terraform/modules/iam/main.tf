/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 SPDX-License-Identifier: MIT-0 */

# --- module/iam/main.tf ---

# ---------- EC2 INSTANCE IAM ROLE (SSM ACCESS) ---------
# IAM instance profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile_${var.identifier}"
  role = aws_iam_role.role_ec2.id
}

# IAM role
resource "aws_iam_role" "role_ec2" {
  name               = "ec2_ssm_role_${var.identifier}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.policy_document.json
}

data "aws_iam_policy_document" "policy_document" {
  statement {
    sid     = "1"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

  }
}

# Policies Attachment to Role
resource "aws_iam_policy_attachment" "ssm_iam_role_policy_attachment" {
  name       = "ssm_iam_role_policy_attachment_${var.identifier}"
  roles      = [aws_iam_role.role_ec2.id]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}