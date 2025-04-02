# Local variables
locals {
  instance_name = "${var.resource_prefix}-security-agent"
}

# Get the current AWS account ID
data "aws_caller_identity" "current" {}

# Get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Get the default subnet in the first availability zone
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# Create a key pair using the provided public key
resource "aws_key_pair" "ssh_key" {
  key_name   = "${var.resource_prefix}-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Security group for Elastic Agent
resource "aws_security_group" "elastic_agent" {
  name        = "${var.resource_prefix}-elastic-agent-sg"
  description = "Security group for Elastic Agent"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
}

# 1. Enable AWS Security Hub for the current account
resource "aws_securityhub_account" "main" {}

# 2. Enable only the CIS AWS Foundations Benchmark to reduce cost
resource "aws_securityhub_standards_subscription" "cis" {
  depends_on    = [aws_securityhub_account.main]
  standards_arn = "arn:aws:securityhub:${var.aws_region}::standards/aws-foundational-security-best-practices/v/1.0.0"
}

# 3. Explicitly disable unnecessary controls to avoid being charged for them
# Example: IAM.1 - IAM policies should not allow full "*" administrative privileges
resource "aws_securityhub_standards_control" "disable_iam_full_admin" {
  depends_on            = [aws_securityhub_standards_subscription.cis]
  standards_control_arn = "arn:aws:securityhub:${var.aws_region}:${data.aws_caller_identity.current.account_id}:control/aws-foundational-security-best-practices/v/1.0.0/IAM.1"
  control_status        = "DISABLED"
  disabled_reason       = "Managed through other policies."
}

# Disable additional AWS FSBP controls
resource "aws_securityhub_standards_control" "disable_iam_root_access" {
  depends_on            = [aws_securityhub_standards_subscription.cis]
  standards_control_arn = "arn:aws:securityhub:${var.aws_region}:${data.aws_caller_identity.current.account_id}:control/aws-foundational-security-best-practices/v/1.0.0/IAM.4"
  control_status        = "DISABLED"
  disabled_reason       = "Root account is locked and not used."
}

resource "aws_securityhub_standards_control" "disable_mfa_requirement" {
  depends_on            = [aws_securityhub_standards_subscription.cis]
  standards_control_arn = "arn:aws:securityhub:${var.aws_region}:${data.aws_caller_identity.current.account_id}:control/aws-foundational-security-best-practices/v/1.0.0/IAM.5"
  control_status        = "DISABLED"
  disabled_reason       = "Using IAM roles instead of IAM users."
}

# Disable additional controls as specified in variables
resource "aws_securityhub_standards_control" "additional_disabled_controls" {
  for_each = toset(var.disabled_security_controls)
  
  depends_on            = [aws_securityhub_standards_subscription.cis]
  standards_control_arn = "arn:aws:securityhub:${var.aws_region}:${data.aws_caller_identity.current.account_id}:control/aws-foundational-security-best-practices/v/1.0.0/${each.value}"
  control_status        = "DISABLED"
  disabled_reason       = "Disabled via Terraform configuration"
}

# 4. (Optional) Integrate with GuardDuty if enabled via variable
resource "aws_securityhub_product_subscription" "guardduty" {
  count       = var.enable_guardduty_integration ? 1 : 0
  depends_on  = [aws_securityhub_account.main]
  product_arn = "arn:aws:securityhub:${var.aws_region}::product/aws/guardduty"
}

# IAM user for Elastic Agent to access Security Hub
resource "aws_iam_user" "elastic_agent" {
  name = "${var.resource_prefix}-elastic-agent-user"
  path = "/"
}

# IAM policy for Security Hub access
resource "aws_iam_policy" "security_hub_access" {
  name        = "${var.resource_prefix}-security-hub-access"
  description = "Policy to allow access to Security Hub findings"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "securityhub:GetFindings",
          "securityhub:GetInsights",
          "securityhub:ListFindings",
          "securityhub:ListInsights",
          "securityhub:DescribeHub",
          "securityhub:DescribeProducts",
          "securityhub:DescribeStandards",
          "securityhub:DescribeStandardsControls",
          "ec2:DescribeRegions",
          "iam:ListAccountAliases",
          "sts:GetCallerIdentity"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach the policy to the IAM user
resource "aws_iam_user_policy_attachment" "security_hub_access" {
  user       = aws_iam_user.elastic_agent.name
  policy_arn = aws_iam_policy.security_hub_access.arn
}

# Create access keys for the IAM user
resource "aws_iam_access_key" "elastic_agent" {
  user = aws_iam_user.elastic_agent.name
}

# EC2 instance for Elastic Agent
resource "aws_instance" "elastic_agent" {
  ami                    = var.ec2_ami
  instance_type          = var.ec2_instance_type
  key_name               = aws_key_pair.ssh_key.key_name
  vpc_security_group_ids = [aws_security_group.elastic_agent.id]
  subnet_id              = tolist(data.aws_subnets.default.ids)[0]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = local.instance_name
  }

  # No user_data as Elastic Agent will be installed manually
}