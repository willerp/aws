######################################################################
# Created and maintained by: Willer Pulis
# Lambda function to set a retention period on all CloudWatch Logs log groups
# INSTRUCTIONS:
######################################################################
#
# The Lambda function needs to be created with two variables: awsRegion and retentionInDays
#
######################################################################

import boto3
import os

# Array of non-compliant CloudWatch Logs log groups
nonCompliantLogGroups = []

# Getting the AWS region from environment variables
awsRegion = os.environ['awsRegion']

# Creating the CloudWatch Logs client
cwlclient = boto3.client('logs', region_name=awsRegion)

# This function checks if the log groups have the correct retention period set
def evaluate(cwlgroups, retentionInDays):
    
    for group in cwlgroups:
        
        grpname = group['logGroupName']
        
        try:
            grpret = group['retentionInDays']
        except KeyError:
            grpret = 0
        
        # Adds the log group to the non-compliant array if the retention is not correct
        if grpret != retentionInDays:
            nonCompliantLogGroups.append(grpname)

# This function sets the retention of non-compliant groups based on the retentionInDays environment variable
def remediate(nonCompliantLogGroups,retentionInDays):
    
    for group in nonCompliantLogGroups:
        cwlclient.put_retention_policy(
            logGroupName = group,
            retentionInDays = retentionInDays
        )

def lambda_handler(event, context):
    
    retentionInDays = int(os.environ['retentionInDays'])
    
    cwlgroups = cwlclient.describe_log_groups()
    evaluate(cwlgroups['logGroups'],retentionInDays)
    
    if 'nextToken' in cwlgroups:
        while True:
            cwlgroups = cwlclient.describe_log_groups(nextToken=cwlgroups['nextToken'])
            evaluate(cwlgroups['logGroups'],retentionInDays)
            if not 'nextToken' in cwlgroups:
                break
    
    print("Number of log groups to be remediated: " + str(len(nonCompliantLogGroups)))
    remediate(nonCompliantLogGroups,retentionInDays)
    
    return "Complete."