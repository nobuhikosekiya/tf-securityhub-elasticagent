variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "aws_profile" {
  description = "AWS profile to use for API calls"
  type        = string
  default     = "elastic-sa"
}

variable "resource_prefix" {
  description = "Prefix for all resources"
  type        = string
  default     = "elastic"
}

variable "default_tags" {
  description = "AWS default tags for resources"
  type        = map(string)
  default     = {}
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "ec2_ami" {
  description = "EC2 AMI ID"
  type        = string
  default     = "ami-0599b6e53ca798bb2"
}

variable "security_hub_regions" {
  description = "Regions to enable Security Hub in"
  type        = list(string)
  default     = ["ap-northeast-1"]
}

variable "enable_guardduty_integration" {
  description = "Whether to enable GuardDuty integration with Security Hub"
  type        = bool
  default     = false
}

variable "disabled_security_controls" {
  description = "List of additional Security Hub control IDs to disable (e.g., IAM.2, EC2.1)"
  type        = list(string)
  default     = []
}