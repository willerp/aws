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

nonCompliantLogGroups = []
awsRegion = os.environ['awsRegion']
cwlclient = boto3.client('logs', region_name=awsRegion)

def evaluate(cwlgroups):
    
    for group in cwlgroups:
        
        grpname = group['logGroupName']
        
        try:
            grpret = group['retentionInDays']
        except KeyError:
            grpret = 0
            
        if grpret != 30:
            nonCompliantLogGroups.append(grpname)

def remediate(nonCompliantLogGroups,retentionInDays):
    
    for group in nonCompliantLogGroups:
        cwlclient.put_retention_policy(
            logGroupName = group,
            retentionInDays = retentionInDays
        )

def lambda_handler(event, context):
    
    retentionInDays = int(os.environ['retentionInDays'])
    
    cwlgroups = cwlclient.describe_log_groups()
    evaluate(cwlgroups['logGroups'])
    
    if 'nextToken' in cwlgroups:
        while True:
            cwlgroups = cwlclient.describe_log_groups(nextToken=cwlgroups['nextToken'])
            evaluate(cwlgroups['logGroups'])
            if not 'nextToken' in cwlgroups:
                break
    
    print("Number of log groups to be remediated: " + str(len(nonCompliantLogGroups)))
    remediate(nonCompliantLogGroups,retentionInDays)