output "elastic_agent_instance_id" {
  description = "ID of the EC2 instance running Elastic Agent"
  value       = aws_instance.elastic_agent.id
}

output "elastic_agent_public_ip" {
  description = "Public IP address of the EC2 instance running Elastic Agent"
  value       = aws_instance.elastic_agent.public_ip
}

output "elastic_agent_public_dns" {
  description = "Public DNS name of the EC2 instance running Elastic Agent"
  value       = aws_instance.elastic_agent.public_dns
}

output "security_hub_account_enabled" {
  description = "Whether Security Hub is enabled in the account"
  value       = aws_securityhub_account.main.id
}

output "security_hub_cis_standard_enabled" {
  description = "The ARN of the enabled AWS Foundational Security Best Practices standard"
  value       = aws_securityhub_standards_subscription.cis.standards_arn
}

output "guardduty_integration_enabled" {
  description = "Whether GuardDuty integration is enabled"
  value       = var.enable_guardduty_integration ? "Yes" : "No"
}

output "elastic_agent_iam_user" {
  description = "Name of the IAM user created for Elastic Agent"
  value       = aws_iam_user.elastic_agent.name
}

output "elastic_agent_access_key_id" {
  description = "Access Key ID for the Elastic Agent IAM user"
  value       = aws_iam_access_key.elastic_agent.id
}

output "elastic_agent_secret_access_key" {
  description = "Secret Access Key for the Elastic Agent IAM user"
  value       = aws_iam_access_key.elastic_agent.secret
  sensitive   = true
}

output "ssh_command" {
  description = "SSH command to connect to the EC2 instance"
  value       = "ssh ec2-user@${aws_instance.elastic_agent.public_ip}"
}