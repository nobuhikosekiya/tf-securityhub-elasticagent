#!/usr/bin/env python3
"""
Test script to create benign Security Hub findings for testing purposes.
This script creates custom findings that are clearly labeled as test findings
and do not represent actual security issues.
"""

import argparse
import boto3
import json
import uuid
import time
from datetime import datetime, timezone

def parse_args():
    parser = argparse.ArgumentParser(description='Create test Security Hub findings')
    parser.add_argument('--profile', default=None, help='AWS profile to use')
    parser.add_argument('--region', default='ap-northeast-1', help='AWS region')
    parser.add_argument('--count', type=int, default=3, help='Number of test findings to create')
    return parser.parse_args()

def create_test_finding(securityhub, count):
    """Create a test Security Hub finding that is clearly labeled as a test"""
    
    # Generate a unique ID for this finding
    finding_id = str(uuid.uuid4())
    
    # Current timestamp in ISO8601 format
    now = datetime.now(timezone.utc).isoformat()
    
    # Create a benign test finding
    finding = {
        "SchemaVersion": "2018-10-08",
        "Id": finding_id,
        "ProductArn": f"arn:aws:securityhub:{args.region}:{account_id}:product/{account_id}/default",
        "GeneratorId": "elastic-security-hub-test",
        "AwsAccountId": account_id,
        "Types": [
            "Software and Configuration Checks/Vulnerabilities/Test"
        ],
        "CreatedAt": now,
        "UpdatedAt": now,
        "Severity": {
            "Product": 0,  # Lowest severity
            "Normalized": 0  # Lowest normalized severity
        },
        "Title": f"TEST FINDING {count} - Safe for Testing - Will Auto-Resolve",
        "Description": "This is a test finding created by the Elastic Security Hub test script. "
                      "This finding does not represent a real security issue and is safe to ignore. "
                      "This finding will automatically resolve after 24 hours.",
        "ProductFields": {
            "TestScenario": "elastic-security-hub-test",
            "TestRunId": str(uuid.uuid4())
        },
        "Resources": [
            {
                "Type": "AwsAccount",
                "Id": f"arn:aws:iam::{account_id}:root",
                "Partition": "aws",
                "Region": args.region
            }
        ],
        "WorkflowState": "NEW",
        "RecordState": "ACTIVE",
        "Compliance": {
            "Status": "NOT_AVAILABLE"
        }
    }
    
    try:
        response = securityhub.batch_import_findings(
            Findings=[finding]
        )
        
        if response['FailedCount'] > 0:
            print(f"Failed to import finding: {response['FailedFindings']}")
            return False
        
        print(f"Successfully created test finding {count}: {finding_id}")
        return True
    
    except Exception as e:
        print(f"Error creating finding: {e}")
        return False

if __name__ == "__main__":
    args = parse_args()
    
    # Set up boto3 session
    session = boto3.Session(profile_name=args.profile, region_name=args.region)
    securityhub = session.client('securityhub')
    sts = session.client('sts')
    
    # Get the current AWS account ID
    account_id = sts.get_caller_identity()['Account']
    
    print(f"Creating {args.count} test findings in Security Hub...")
    
    successful_findings = 0
    
    for i in range(1, args.count + 1):
        if create_test_finding(securityhub, i):
            successful_findings += 1
        time.sleep(1)  # Adding a small delay between creations
    
    print(f"Created {successful_findings} out of {args.count} test findings in Security Hub.")
    print("NOTE: These findings are benign and labeled as tests. They will automatically resolve after 24 hours.")