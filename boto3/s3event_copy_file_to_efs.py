import os
import boto3
from urllib.parse import unquote

def lambda_handler(event, context):
    
    s3 = boto3.resource('s3')
    
    # Getting uploaded object reference
    s3bucket = event['Records'][0]['s3']['bucket']['name']
    s3object = unquote((event['Records'][0]['s3']['object']['key']).replace("+", " "))
    print('s3bucket: '+s3bucket)
    print('s3object: '+s3object)
    
    # Assembling file name with path
    if s3object.rfind('/') > 0:
        osFile = '/tmp/'+s3object[s3object.find('/')+1:]
    else:
        osFile = '/tmp/'+s3object
    
    # Downloading file from S3
    print('Downloading '+s3object+' from S3 bucket '+s3bucket+' to '+osFile)
    s3.Object(s3bucket,s3object).download_file(osFile)

    # Copying to EFS
    print('Copying file to EFS. Copy command:')
    copyCmd = 'cp "' + osFile + '" /mnt/esi-dev/esi-efs-dev/IN'
    print(copyCmd)
    os.system(copyCmd)
    