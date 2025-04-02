# AWS Security Hub Terraform Configuration

This repository contains Terraform configurations to set up AWS Security Hub with minimal checks and deploy EC2 infrastructure for security monitoring with Elastic Agent.

## Overview

This project enables AWS Security Hub with optimized configurations to reduce costs while maintaining essential security monitoring. It also creates an EC2 instance with appropriate IAM permissions to collect Security Hub findings and forward them to your Elastic Stack.

### Features

- Enables AWS Security Hub with AWS Foundational Security Best Practices (FSBP) standard
- Disables unnecessary security controls to optimize costs
- Provisions an EC2 instance for running Elastic Agent
- Creates IAM users and access keys with proper permissions
- Optional GuardDuty integration
- Includes testing scripts to verify setup

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (v1.0.0 or newer)
- AWS CLI configured with appropriate credentials
- SSH key pair for EC2 access (default: `~/.ssh/id_rsa.pub`)
- Python 3.6+ with pip (for running test scripts)

## Quick Start

1. **Clone this repository**

```bash
git clone https://github.com/your-org/aws-security-hub-terraform.git
cd aws-security-hub-terraform
```

2. **Configure variables**

Create a `terraform.tfvars` file based on the example:

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your preferred configuration
```

3. **Initialize Terraform**

```bash
terraform init
```

4. **Plan the deployment**

```bash
terraform plan
```

5. **Apply the configuration**

```bash
terraform apply
```

6. **Run the test script (optional)**

Install Python dependencies:
```bash
pip install -r requirements.txt
```

Create test findings (replace profile if needed):
```bash
python test_security_hub.py --profile your-aws-profile --count 3
```

## Architecture

The deployment creates the following resources:

- **AWS Security Hub** enabled with AWS Foundational Security Best Practices standard
- **EC2 Instance** for running Elastic Agent
- **IAM User and Access Keys** for secure access to Security Hub API
- **Security Groups** for network access control
- **SSH Key Pair** for EC2 access

### Architecture Diagram

```
                  +-------------------+
                  |                   |
+------------+    |   AWS Security    |    +----------------+
| Test Script|--->|      Hub          |<---| Disabled       |
+------------+    |  (FSBP Standard)  |    | Controls       |
                  |                   |    +----------------+
                  +-------------------+
                           |
                           | Findings
                           v
                  +-------------------+
                  |                   |
                  |    IAM User       |
                  |    with Keys      |
                  |                   |
                  +-------------------+
                           |
                           | Credentials
                           v
+------------+    +-------------------+
| Security   |--->|                   |
| Group      |    |   EC2 Instance    |
+------------+    |   (Elastic Agent) |
                  |                   |
                  +-------------------+
                           |
                           | Forwards Findings
                           v
                  +-------------------+
                  |                   |
                  |   Elastic Stack   |
                  |   (Your Deployment)|
                  |                   |
                  +-------------------+
```

The diagram above illustrates the complete architecture and data flow:
1. AWS Security Hub collects security findings across your AWS account
2. The IAM user provides secure, limited access to Security Hub findings
3. An EC2 instance runs Elastic Agent to forward findings to your Elastic Stack
4. Specific Security Hub controls are disabled to optimize costs
5. Testing scripts can create benign test findings to verify the integration

## Security Hub Configuration

The configuration enables AWS Security Hub with a cost-optimized approach:

1. Enables the AWS Foundational Security Best Practices (FSBP) standard
   - More widely supported across regions than CIS Benchmark
   - Provides comprehensive security controls maintained by AWS

2. Disables specific controls that aren't needed:
   - IAM.1 (IAM policies should not allow full "*" administrative privileges)
   - IAM.4 (Root user access keys should not exist)
   - IAM.5 (MFA should be enabled for all IAM users)

3. Allows additional controls to be disabled via variables

4. Optional integration with GuardDuty (disabled by default)

## Customization

### Disabling Additional Security Controls

To disable specific security controls, add their IDs to the `disabled_security_controls` variable in your `terraform.tfvars` file:

```hcl
disabled_security_controls = [
  "IAM.2",  # IAM users should not have IAM policies attached
  "EC2.1",  # EBS snapshots should not be public
  "S3.1",   # S3 Block Public Access setting should be enabled
  "CloudTrail.1"  # CloudTrail should be enabled and configured with at least one multi-region trail
]
```

### Changing AWS Region

To deploy in a different AWS region, update the `aws_region` variable in your `terraform.tfvars` file:

```hcl
aws_region = "us-east-1"  # Change to your preferred region
```

### Enabling GuardDuty Integration

To enable GuardDuty integration with Security Hub:

```hcl
enable_guardduty_integration = true
```

Note: This requires GuardDuty to be already enabled in your AWS account.

## Elastic Agent Configuration (Manual)

After deploying the infrastructure, you'll need to manually install the Elastic Agent on the EC2 instance:

1. SSH into the EC2 instance:
   ```bash
   ssh -i ~/.ssh/id_rsa ec2-user@$(terraform output -raw elastic_agent_public_ip)
   ```

2. Install and configure Elastic Agent with Security Hub integration
   - Follow Elastic's documentation for agent installation
   - Configure the agent to use the IAM access keys that were created
   - The access key ID and secret can be obtained from Terraform outputs:
     ```bash
     terraform output -raw elastic_agent_access_key_id
     terraform output -raw elastic_agent_secret_access_key
     ```

3. Example agent configuration for Security Hub:
   ```yaml
   inputs:
     - type: aws
       id: aws-security-hub
       enabled: true
       streams:
         - data_stream.dataset: aws.securityhub
           data_stream.type: logs
           period: 300s
           aws.regions:
             - ap-northeast-1
           aws.credentials:
             access_key_id: ${ACCESS_KEY_ID}
             secret_access_key: ${SECRET_ACCESS_KEY}
           tags:
             - security
   ```

## Testing

A Python test script is included to create benign Security Hub findings for testing purposes:

```bash
python test_security_hub.py --profile your-aws-profile --region ap-northeast-1 --count 3
```

This will create harmless test findings that:
- Are clearly labeled as test findings
- Have minimal severity (0)
- Will auto-resolve after 24 hours
- Do not represent actual security issues

### GitHub Actions

This repository includes a GitHub Actions workflow that:
1. Runs Terraform validation and formatting checks
2. Applies the Terraform configuration (on main branch)
3. Runs the test script to create test findings
4. Verifies the findings were properly created

To use it, you'll need to configure the `AWS_ROLE_TO_ASSUME` secret in your GitHub repository.

## Outputs

The deployment provides several useful outputs:

- `elastic_agent_instance_id`: ID of the EC2 instance
- `elastic_agent_public_ip`: Public IP address of the EC2 instance
- `elastic_agent_access_key_id`: Access Key ID for the Elastic Agent IAM user
- `elastic_agent_secret_access_key`: Secret Access Key for the Elastic Agent IAM user
- `security_hub_account_enabled`: Confirmation that Security Hub is enabled
- `security_hub_cis_standard_enabled`: The ARN of the enabled FSBP standard
- `ssh_command`: Ready-to-use SSH command to connect to the instance

## Cost Optimization

This configuration minimizes AWS costs by:

1. Enabling only essential security standards (AWS FSBP)
2. Disabling unnecessary security controls
3. Using minimal instance size (configurable)
4. Making GuardDuty integration optional

## Maintenance

### Updating Security Controls

To modify which security controls are enabled/disabled:

1. Update the `disabled_security_controls` variable
2. Run `terraform apply` to apply changes

### Destroying Resources

To remove all resources created by this configuration:

```bash
terraform destroy
```

## Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure your AWS profile has sufficient permissions (SecurityHub, IAM, EC2)
2. **SSH Access Issues**: Verify your SSH key is properly configured
3. **Security Hub API Errors**: Check IAM permissions for the IAM user
4. **Test Script Failures**: Ensure the AWS profile has permission to create SecurityHub findings

### Checking Security Hub Findings

To view Security Hub findings in the AWS console:
1. Go to AWS Security Hub in the console
2. Click on "Findings" in the left menu
3. Look for findings with "TEST FINDING" in the title to see test findings

Or using the AWS CLI:
```bash
aws securityhub get-findings --filter '{"GeneratorId":[{"Value":"elastic-security-hub-test","Comparison":"EQUALS"}]}'
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.