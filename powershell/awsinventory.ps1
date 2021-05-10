# This is a Powershell script run an inventory of some AWS services
# Created and maintained by: Willer Pulis
# If you are using AWS CloudShell, enter the Powershell environment by running the command "pwsh"
# Then run the two following commands:
# Install-Module AWSPowerShell
# Import-Module AWSPowerShell
######################################################################
#
# ATTENTION: if you are using linux systems, change line 24 from 
#            $path+=$date+"\"
#            to
#            $path+=$date+"/"
#
# ATTENTION: Replace placeholders on the accounts array $accinfo
#
######################################################################

# Getting current date
$date=Get-Date -Format yyyy-MM-dd

# Insert your data
# Insert the path with a \ at the end (windows) or / (linux)
$path=""
$path+=$date+"\"

# Set and Create Path
Write-Host "Setting and creating path"
Write-Host
if(!(Test-Path -Path $path)){
    New-Item -Path $path -ItemType "directory"
}

# Initialize credentials, add as many accounts as you wish to this array
$accinfo = @(
    [pscustomobject]@{AccName="<ACCOUNT_ALIAS>";Profile="<PROFILE_NAME>";AccID=<ACCOUNT_ID>;AccessKey="<ACCESS_KEY>";SecretKey="<SECREY_KEY>";SessionToken="<SESSION_TOKEN>"}
)

#Store profiles accounts
$accinfo | foreach {
    Set-AWSCredential -AccessKey $_.AccessKey -SecretKey $_.SecretKey -StoreAs $_.Profile
}

#Looping through all accounts
foreach ($acc in $accinfo) {
    Set-AWSCredential -ProfileName $acc.Profile

    $accname=$acc.AccName
    $accid=$acc.AccID
    
    Write-Host "RESOURCE INVENTORY FOR ACCOUNT $accname"
    Write-Host
    foreach ($region in (Get-EC2Region).RegionName) {
        Write-Host
        Write-Host "REGION: $region"
        Write-Host
        
        # Customer Gateways
        Write-Host "Gathering Customer Gateways for region $region"
        foreach ($cgw in (Get-EC2CustomerGateway -Region $region)){
            New-Object -TypeName PSObject -Property @{
                'AccountName' = $accname
                'AccountId' = $accid
                'Region' = $region
                'Name' = ($cgw.Tags | Where-Object {$_.Key -eq 'Name'}).Value
                'CustomerGatewayId' = $cgw.CustomerGatewayId
                'IpAddress' = $cgw.IpAddress
                'BgpAsn' = $cgw.BgpAsn
            } | Select-Object AccountName,AccountId,Region,Name,CustomerGatewayId,IpAddress,BgpAsn `
                | Export-Csv -Path "$($path)awsinventory_cgw_$($date).csv" -Encoding ascii -NoTypeInformation -Append -Force
        }
        
        # Virtual Private Gateways
        Write-Host "Gathering Virtual Private Gateways for region $region"
        foreach ($vgw in (Get-EC2VpnGateway -Region $region)){
            New-Object -TypeName PSObject -Property @{
                'AccountName' = $accname
                'AccountId' = $accid
                'Region' = $region
                'Name' = ($vgw.Tags | Where-Object {$_.Key -eq 'Name'}).Value
                'VirtualPrivateGatewayId' = $vgw.VpnGatewayId
                'State' = $vgw.State.Value
                'AmazonSideAsn' = $vgw.AmazonSideAsn
                'VpcAttachmentsState' = $vgw.VpcAttachments.State.Value
                'VpcAttachmentsVpcId' = $vgw.VpcAttachments.VpcId
            } | Select-Object AccountName,AccountId,Region,Name,VirtualPrivateGatewayId,State,AmazonSideAsn,VpcAttachmentsState,VpcAttachmentsVpcId `
                | Export-Csv -Path "$($path)awsinventory_vgw_$($date).csv" -Encoding ascii -NoTypeInformation -Append -Force
        }
        
        # Direct Connect Connections
        Write-Host "Gathering Direct Connect Connections for region $region"
        foreach ($dx in (Get-DCConnection -Region $region)){
            New-Object -TypeName PSObject -Property @{
                'AccountName' = $accname
                'AccountId' = $accid
                'Region' = $region
                'ConnectionId' = $dx.ConnectionId
                'ConnectionName' = $dx.ConnectionName
                'ConnectionState' = $dx.ConnectionState
                'Bandwidth' = $dx.Bandwidth
                'OwnerAccount' = $dx.OwnerAccount
                'Location' = $dx.Location
                'PartnerName' = $dx.PartnerName
                'Vlan' = $dx.Vlan
                'AwsDevice' = $dx.AwsDevice
                'AwsDeviceV2' = $dx.AwsDeviceV2
            } | Select-Object AccountName,AccountId,Region,ConnectionId,ConnectionName,ConnectionState,Bandwidth,OwnerAccount,Location,PartnerName,Vlan,AwsDevice,AwsDeviceV2  `
                | Export-Csv -Path "$($path)awsinventory_dx_conn_$($date).csv" -Encoding ascii -NoTypeInformation -Append -Force
        }

        # Direct Connect Gateways
        Write-Host "Gathering Direct Connect Gateways for region $region"
        foreach ($dxgtw in (Get-DCGateway -Region sa-east-1)){
            New-Object -TypeName PSObject -Property @{
                'AccountName' = $accname
                'AccountId' = $accid
                'Region' = $region
                'DirectConnectGatewayId' = $dxgtw.DirectConnectGatewayId
                'DirectConnectGatewayName' = $dxgtw.DirectConnectGatewayName
                'DirectConnectGatewayState' = $dxgtw.DirectConnectGatewayState
                'OwnerAccount' = $dxgtw.OwnerAccount
                'AmazonSideAsn' = $dxgtw.AmazonSideAsn
            } | Select-Object AccountName,AccountId,Region,DirectConnectGatewayId,DirectConnectGatewayName,DirectConnectGatewayState,OwnerAccount,AmazonSideAsn  `
                | Export-Csv -Path "$($path)awsinventory_dx_gtw_$($date).csv" -Encoding ascii -NoTypeInformation -Append -Force
            #Get-DCGatewayAssociation -Region $region -DirectConnectGatewayId $dxgtw.DirectConnectGatewayId
            #Get-DCGatewayAttachment -Region $region -DirectConnectGatewayId $dxgtw.DirectConnectGatewayId
        }

        # Direct Connect Virtual Interfaces
        Write-Host "Gathering Direct Connect Gateways for region $region"
        foreach ($vif in (Get-DCVirtualInterface -region $region)) {
            New-Object -TypeName PSObject -Property @{
                'AccountName' = $accname
                'AccountId' = $accid
                'OwnerAccount' = $vif.OwnerAccount
                'VirtualInterfaceId' = $vif.VirtualInterfaceId
                'VirtualInterfaceName' = $vif.VirtualInterfaceName
                'VirtualGatewayId' = $vif.VirtualGatewayId
                'Region' = $vif.Region
                'VirtualInterfaceState' = $vif.VirtualInterfaceState
                'VirtualInterfaceType' = $vif.VirtualInterfaceType
                'Vlan' = $vif.Vlan
                'AddressFamily' = $vif.AddressFamily
                'AmazonAddress' = $vif.AmazonAddress
                'AmazonSideAsn' = $vif.AmazonSideAsn
                'Asn' = $vif.Asn
                'ConnectionId' = $vif.ConnectionId
                'CustomerAddress' = $vif.CustomerAddress
                'DirectConnectGatewayId' = $vif.DirectConnectGatewayId
                'Mtu' = $vif.Mtu
            } | Select-Object AccountName,AccountId,OwnerAccount,VirtualInterfaceId,VirtualInterfaceName,VirtualGatewayId,Region,VirtualInterfaceState, `
                VirtualInterfaceType,Vlan,AddressFamily,AmazonAddress,AmazonSideAsn,Asn,ConnectionId,CustomerAddress,DirectConnectGatewayId,Mtu `
                | Export-Csv -Path "$($path)awsinventory_dx_vif_$($date).csv" -Encoding ascii -NoTypeInformation -Append -Force
        }
        
        # VPCs
        Write-Host "Gathering VPCs for region $region"
        foreach ($vpc in (Get-EC2Vpc -Region $region)) {
            $vpc.CidrBlockAssociationSet | foreach {
                New-Object -TypeName PSObject -Property @{
                    'AccountName' = $accname
                    'AccountId' = $accid
                    'Region' = $region
                    'VPCId' = $vpc.VPCId
                    'VPCName' = ($vpc.Tags | Where-Object {$_.Key -eq 'Name'}).Value
                    'CidrBlock' = $_.CidrBlock
                    'IsDefault' = $vpc.IsDefault
                }
            }  | Select-Object AccountName,AccountId,Region,VPCId,VPCName,CidrBlock,IsDefault | Export-Csv -Path "$($path)awsinventory_vpcs_$($date).csv" -Encoding ascii -NoTypeInformation -Append -Force
        }
        
        # Subnets
        Write-Host "Gathering Subnets for region $region"
        foreach ($subnet in (Get-EC2Subnet -Region $region)) {
            New-Object -TypeName PSObject -Property @{
                'AccountName' = $accname
                'AccountId' = $accid
                'Region' = $region
                'SubnetId' = $subnet.SubnetId
                'SubnetName' = ($subnet.Tags | Where-Object {$_.Key -eq 'Name'}).Value
                'CidrBlock' = $subnet.CidrBlock
                'AvailabilityZone' = $subnet.AvailabilityZone
                'VpcId' = $subnet.VpcId
            } | Select-Object AccountName,AccountId,Region,SubnetId,SubnetName,CidrBlock,AvailabilityZone,VpcId | Export-Csv -Path "$($path)awsinventory_subnets_$($date).csv" -Encoding ascii -NoTypeInformation -Append -Force
        }
        
        # EC2 instances
        Write-Host "Gathering EC2 instances for region $region"
        $Instances = (Get-EC2Instance -Region $region).instances
        foreach ($VPC in (Get-EC2Vpc -Region $region)) {
             $Instances | Where-Object {$_.VpcId -eq $VPC.VpcId} | foreach {
                New-Object -TypeName PSObject -Property @{
                    'AccountName' = $accname
                    'AccountId' = $accid
                    'Region' = $region
                    'VpcId' = $_.VpcId
                    'VPCName' = ($VPC.Tags | Where-Object {$_.Key -eq 'Name'}).Value
                    'InstanceId' = $_.InstanceId
                    'InstanceName' = ($_.Tags | Where-Object {$_.Key -eq 'Name'}).Value
                    'Hostname' = ($_.Tags | Where-Object {$_.Key -eq 'hostname'}).Value
                    'Company' = ($_.Tags | Where-Object {$_.Key -eq 'company'}).Value
                    'Environment' = ($_.Tags | Where-Object {$_.Key -eq 'environment'}).Value
                    'AppName' = ($_.Tags | Where-Object {$_.Key -eq 'app-name'}).Value
                    'BusinessUnit' = ($_.Tags | Where-Object {$_.Key -eq 'business-unit'}).Value
                    'PlatformTag' = ($_.Tags | Where-Object {$_.Key -eq 'platform'}).Value
                    'LaunchTime' = $_.LaunchTime
                    'State' = $_.State.Name
                    'Architecture' = $_.Architecture
                    'Hypervisor' = $_.Hypervisor
                    'Platform' = $_.Platform
                    'InstanceType' = $_.InstanceType
                    'SubnetId' = $_.SubnetId
                    'PrivateDnsName' = $_.PrivateDnsName
                    'PrivateIpAddress' = $_.PrivateIpAddress
                    'PublicDnsName' = $_.PublicDnsName
                    'PublicIPAddress' = $_.PublicIPAddress
                }
            } | Select-Object AccountName,AccountId,Region,VpcId,VPCName,InstanceId,InstanceName,Hostname,Company,Environment, `
                AppName,BusinessUnit,PlatformTag,LaunchTime,State,Architecture,Hypervisor,Platform,InstanceType,SubnetId, `
                PrivateDnsName,PrivateIpAddress,PublicDnsName,PublicIPAddress  `
                | Export-Csv -Path "$($path)awsinventory_ec2_$($date).csv" -Encoding ascii -NoTypeInformation -Append -Force
        }
        
        # EBS volumes
        Write-Host "Gathering EBS volumes for region $region"
        (Get-EC2Volume -Region $region) | foreach {
            New-Object -TypeName PSObject -Property @{
                'AccountName' = $accname
                'AccountId' = $accid
                'Region' = $region
                'VolumeId' = $volume.VolumeId
                'VolumeType' = $volume.VolumeType
                'Size' = $volume.Size
                'AvailabilityZone' = $volume.AvailabilityZone
                'State' = $volune.State
                'Attachments' = $volume.Attachments
                'Encrypted' = $volume.Encrypted
                'KmsKeyId' = $volume.KmsKeyId
                'Name' = ($_.Tags | Where-Object {$_.Key -eq 'Name'}).Value
                'Company' = ($_.Tags | Where-Object {$_.Key -eq 'company'}).Value
                'Environment' = ($_.Tags | Where-Object {$_.Key -eq 'environment'}).Value
                'AppName' = ($_.Tags | Where-Object {$_.Key -eq 'app-name'}).Value
                'BusinessUnit' = ($_.Tags | Where-Object {$_.Key -eq 'business-unit'}).Value
                'PlatformTag' = ($_.Tags | Where-Object {$_.Key -eq 'platform'}).Value
            }
        } | Select-Object AccountName,AccountId,Region,VolumeId,VolumeType,Size,AvailabilityZone,State,Attachments, `
            Encrypted,KmsKeyId,Name,Company,Environment,AppName,BusinessUnit,PlatformTag  `
            | Export-Csv -Path "$($path)awsinventory_ebs_volumes_$($date).csv" -Encoding ascii -NoTypeInformation -Append -Force

        
        # Classic ELBs
        Write-Host "Gathering Classic ELBs for region $region"
        (Get-ELBLoadBalancer -Region $region) | foreach {
            New-Object -TypeName PSObject -Property @{
                'AccountName' = $accname
                'AccountId' = $accid
                'Region' = $region
                'VPCId' = $_.VPCId
                'State' = ''
                'DNSName' = $_.DNSName
                'CreatedTime' = $_.CreatedTime
                'Scheme' = $_.Scheme
            }
        } | Select-Object AccountName,AccountId,Region,VPCId,State,DNSName,CreatedTime,Scheme | Export-Csv -Path "$($path)awsinventory_classicelb_$($date).csv" -Encoding ascii -NoTypeInformation -Append -Force
        
        # Application ELBs
        Write-Host "Gathering Application ELBs for region $region"
        (Get-ELB2LoadBalancer -Region $region) | foreach {
            New-Object -TypeName PSObject -Property @{
                'AccountName' = $accname
                'AccountId' = $accid
                'Region' = $region
                'VPCId' = $_.VPCId
                'State' = $_.State.Code
                'DNSName' = $_.DNSName
                'CreatedTime' = $_.CreatedTime
                'Scheme' = $_.Scheme
            }
        } | Select-Object AccountName,AccountId,Region,VPCId,State,DNSName,CreatedTime,Scheme | Export-Csv -Path "$($path)awsinventory_appelb_$($date).csv" -Encoding ascii -NoTypeInformation -Append -Force
    
        # RDS Instances
        Write-Host "Gathering RDS instances for region $region"
        (Get-RDSDBInstance -Region $region) | foreach {
            New-Object -TypeName PSObject -Property @{
                'AccountName' = $accname
                'AccountId' = $accid
                'Region' = $region
                'DBInstanceIdentifier' = $_.DBInstanceIdentifier
                'DBName' = $_.DBName
                'AvailabilityZone' = $_.AvailabilityZone
                'DBInstanceClass' = $_.DBInstanceClass
                'DBInstanceStatus' = $_.DBInstanceStatus
                'AllocatedStorage' = $_.AllocatedStorage
                'DBInstancePort' = $_.DBInstancePort
                'MasterUsername' = $_.MasterUsername
                'PubliclyAccessible' = $_.PubliclyAccessible
                'ReadReplicaSourceDBInstaceIdentifier' = $_.ReadReplicaSourceDBInstaceIdentifier
                'Engine' = $_.Engine
                'EngineVersion' = $_.EngineVersion
                'InstanceCreateTime' = $_.InstanceCreateTime
            }
        } | Select-Object AccountName,AccountId,Region,DBInstanceIdentifier,DBName,AvailabilityZone,DBInstanceClass, `
            DBInstanceStatus,AllocatedStorage,DBInstancePort,MasterUsername,PubliclyAccessible, `
            ReadReplicaSourceDBInstaceIdentifier,Engine,EngineVersion,InstanceCreateTime  `
            | Export-Csv -Path "$($path)awsinventory_rds_$($date).csv" -Encoding ascii -NoTypeInformation -Append -Force
    
        # Elastic File Systems
        Write-Host "Gathering EFSs for region $region"
        try {
            (Get-EFSFileSystem -Region $region) | foreach {
                New-Object -TypeName PSObject -Property @{
                    'AccountName' = $accname
                    'AccountId' = $accid
                    'Region' = $region
                    'Name' = $_.Name
                    'FileSystemId' = $_.FileSystemId
                    'SizeInBytes' = $_.SizeInBytes.Value
                    'NumberOfMountTargets' = $_.NumberOfMountTargets
                    'CreationTime' = $_.CreationTime
                }
            } | Select-Object AccountName,AccountId,Region,Name,FileSystemId,SizeInBytes,NumberOfMountTargets,CreationTime | Export-Csv -Path "$($path)awsinventory_efs_$($date).csv" -Encoding ascii -NoTypeInformation -Append -Force
        }
        catch { }
    
        # CloudWatch Alarms
        Write-Host "Gathering CloudWatch Alarms for region $region"
        (Get-CWAlarm -Region $region) | foreach {
            New-Object -TypeName PSObject -Property @{
                'AccountName' = $accname
                'AccountId' = $accid
                'Region' = $region
                'AlarmName' = $_.AlarmName
                'Namespace' = $_.Namespace
                'MetricName' = $_.MetricName
                'AlarmDescription' = $_.AlarmDescription
                'StateValue' = $_.StateValue
                'StateUpdatedTimestamp' = $_.StateUpdatedTimestamp
                'Dimensions' = $_.Dimensions.Name+':'+$_.Dimensions.Value
            }
        } | Select-Object AccountName,AccountId,Region,AlarmName,Namespace,MetricName,AlarmDescription,StateValue,StateUpdatedTimestamp,Dimensions  `
            | Export-Csv -Path "$($path)awsinventory_cwalarms_$($date).csv" -Encoding ascii -NoTypeInformation -Append -Force
    
        # KMS
        Write-Host "Gathering KMSs for region $region"
        (Get-KMSKeyList -Region $region) | foreach {
            New-Object -TypeName PSObject -Property @{
                'AccountName' = $accname
                'AccountId' = $accid
                'Region' = $region
                'KeyArn' = $_.KeyArn
                'KeyId' = $_.KeyId
            }
        } | Select-Object AccountName,AccountId,Region,KeyArn,KeyId | Export-Csv -Path "$($path)awsinventory_kms_$($date).csv" -Encoding ascii -NoTypeInformation -Append -Force
    
        # VPC Peering
        Write-Host "Gathering VPC Peerings for region $region"
        (Get-EC2VpcPeeringConnection -Region $region) | foreach {
            New-Object -TypeName PSObject -Property @{
                'AccountName' = $accname
                'AccountId' = $accid
                'Region' = $region
                'Name' = ($_.Tags | Where-Object {$_.Key -eq 'Name'}).Value
                'VpcPeeringConnectionId' = $_.VpcPeeringConnectionId
                'Status' = $_.Status.Message
                'RequesterVPC' = $_.RequesterVpcInfo.VpcId
                'AccepterVPC' = $_.AccepterVpcInfo.VpcId
                'RequesterCidr' = $_.RequesterVpcInfo.CidrBlock
                'AccepterCidr' = $_.AccepterVpcInfo.CidrBlock
                'RequesterOwner' = $_.RequesterVpcInfo.OwnerId
                'AccepterOwner' = $_.AccepterVpcInfo.OwnerId

            }
        } | Select-Object AccountName,AccountId,Region,Name,VpcPeeringConnectionId,Status,RequesterVPC,AccepterVPC, `
            RequesterCidr,AccepterCidr,RequesterOwner,AccepterOwner  `
            | Export-Csv -Path "$($path)awsinventory_peering_$($date).csv" -Encoding ascii -NoTypeInformation -Append -Force

        # ECS resources
        Write-Host "Gathering ECS resources for region $region"
        foreach ($cluster in Get-ECSClusters -Region $region){
            #ECS Tasks
            foreach ($task in Get-ECSTaskList -Cluster $cluster -Region $region){
                New-Object -TypeName PSObject -Property @{
                    'AccountName' = $accname
                    'AccountId' = $accid
                    'Region' = $region
                    'ECSCluster' = $cluster
                    'ECSTask' = $task
                } | Select-Object AccountName,AccountId,Region,ECSCluster,ECSTask | Export-Csv -Path "$($path)awsinventory_ecstasks_$($date).csv" -Encoding ascii -NoTypeInformation -Append -Force
            }

            # ECS Services
            foreach ($service in Get-ECSClusterService -Cluster $cluster -Region $region){
                New-Object -TypeName PSObject -Property @{
                    'AccountName' = $accname
                    'AccountId' = $accid
                    'Region' = $region
                    'ECSCluster' = $cluster
                    'ECSService' = $service
                } | Select-Object AccountName,AccountId,Region,ECSCluster,ECSService | Export-Csv -Path "$($path)awsinventory_ecsservices_$($date).csv" -Encoding ascii -NoTypeInformation -Append -Force
            }

            # ECS Clusters
            New-Object -TypeName PSObject -Property @{
                'AccountName' = $accname
                'AccountId' = $accid
                'Region' = $region
                'ECSCluster' = $cluster
            } | Select-Object AccountName,AccountId,Region,ECSCluster | Export-Csv -Path "$($path)awsinventory_ecsclusters_$($date).csv" -Encoding ascii -NoTypeInformation -Append -Force
        }

        # Elastic Beanstalk resources
        Write-Host "Gathering Elastic Beanstalk resources for region $region"
        foreach ($ebapp in Get-EBApplication -Region $region){
            # EB environments
            foreach ($ebenv in Get-EBEnvironment -ApplicationName $ebapp.ApplicationName -Region $region){
                New-Object -TypeName PSObject -Property @{
                    'AccountName' = $accname
                    'AccountId' = $accid
                    'Region' = $region
                    'ApplicationName' = $ebapp.ApplicationName
                    'EnvironmentId' = $ebenv.EnvironmentId
                    'EnvironmentName' = $ebenv.EnvironmentName
                    'CNAME' = $ebenv.CNAME
                    'EndpointURL' = $ebenv.EndpointURL
                    'Health' = $ebenv.Health
                    'HealthStatus' = $ebenv.HealthStatus
                    'PlatformArn' = $ebenv.PlatformArn
                    'SolutionsStackName' = $ebenv.SolutionsStackName
                } | Select-Object AccountName,AccountId,Region,ApplicationName,EnvironmentId,EnvironmentName,CNAME, `
                    EndpointURL,Health,HealthStatus,PlatformArn,SolutionsStackName  `
                    | Export-Csv -Path "$($path)awsinventory_ebenvironments_$($date).csv" -Encoding ascii -NoTypeInformation -Append -Force
            }
            
            # EB applications
            New-Object -TypeName PSObject -Property @{
                'AccountName' = $accname
                'AccountId' = $accid
                'Region' = $region
                'ApplicationName' = $ebapp.ApplicationName
                'CreateDate' = $ebapp.DateCreated
            } | Select-Object AccountName,AccountId,Region,ApplicationName,CreateDate | Export-Csv -Path "$($path)awsinventory_ebapplications_$($date).csv" -Encoding ascii -NoTypeInformation -Append -Force

        }

    }

    # S3 buckets
    Write-Host
    Write-Host "Gathering S3 buckets"
    Write-Host
    Get-S3Bucket | foreach {
        New-Object -Type PSObject -Property @{
            'AccountName' = $accname
            'AccountId' = $accid
            'BucketName' = $_.BucketName
            'CreationDate' = $_.CreationDate
        }
    } | Select-Object AccountName,AccountId,BucketName,CreationDate | Export-Csv -Path "$($path)awsinventory_s3_$($date).csv" -Encoding ascii -NoTypeInformation -Append -Force
    
    Write-Host
    Write-Host "Gathering IAM Users"
    Write-Host
    # IAM Users
    foreach ($user in Get-IAMUsers) {
    
        try {$pwdage=(New-TimeSpan -Start (Get-Date) -End ((Get-IAMLoginProfile -UserName $user.UserName).CreateDate)).Days*(-1)}
        catch {$pwdage='n/a'}
        
        # IAM Users Key Age
        $key1LastUsed = $key1Id = $key1Status = $key1CreateDate = $key1KeyAge = $key1KeyLastUsedDate = $key1KeyLastUsedRegion = $key1KeyLastUsedServiceName = 'n/a'
        $key2LastUsed = $key2Id = $key2Status = $key2CreateDate = $key2KeyAge = $key2KeyLastUsedDate = $key2KeyLastUsedRegion = $key2KeyLastUsedServiceName = 'n/a'
        if ((Get-IAMAccessKey -UserName $user.UserName | Measure-Object).Count -ne 0) {
            $keycount=1
            foreach ($key in (Get-IAMAccessKey -UserName $user.UserName)) {
                if ($keycount -eq 1) {
                    $key1Id = $key.AccessKeyId
                    $key1Status = $key.Status
                    $key1CreateDate = $key.CreateDate
                    $key1KeyAge = (New-TimeSpan -Start (Get-Date) -End $key.CreateDate).Days*(-1)
                    $key1LastUsed = (Get-IAMAccessKeyLastUsed -AccessKeyId $key.AccessKeyId).AccessKeyLastUsed
                    $key1LastUsedDays = (New-TimeSpan -Start (Get-Date) -End $key1KeyLastUsedDate).Days*(-1)
                    $key1KeyLastUsedDate = $key1LastUsed.LastUsedDate
                    $key1KeyLastUsedRegion = $key1LastUsed.Region
                    $key1KeyLastUsedServiceName = $key1LastUsed.ServiceName
                    $keycount++
                } else {
                    $key2Id = $key.AccessKeyId
                    $key2Status = $key.Status
                    $key2CreateDate = $key.CreateDate
                    $key2KeyAge = (New-TimeSpan -Start (Get-Date) -End $key.CreateDate).Days*(-1)
                    $key2LastUsed = (Get-IAMAccessKeyLastUsed -AccessKeyId $key.AccessKeyId).AccessKeyLastUsed
                    $key2LastUsedDays = (New-TimeSpan -Start (Get-Date) -End $key2KeyLastUsedDate).Days*(-1)
                    $key2KeyLastUsedDate = $key2lastused.LastUsedDate
                    $key2KeyLastUsedRegion = $key2lastused.Region
                    $key2KeyLastUsedServiceName = $key2lastused.ServiceName
                }
            }
        }
    
        # IAM Users Password Age & MFA
        New-Object -TypeName PSObject -Property @{
            'AccountName' = $accname
            'AccountId' = $accid
            'UserPath' = $user.Path
            'UserName' = $user.UserName
            'CreateDate' = $user.CreateDate
            'PasswordAge' = $pwdage
            'PasswordLastUsed' = $user.PasswordLastUsed
            'PasswordLastUsedDays' = (New-TimeSpan -Start (Get-Date) -End $user.PasswordLastUsed).Days*(-1)
            'MFA' = if (Get-IAMMFADevice -UserName $user.UserName) {'Enabled'} else {'Disabled'}
            'Key1Id' = $key1Id
            'Key1Status' = $key1Status
            'Key1CreateDate' = $key1CreateDate
            'Key1KeyAge' = $key1KeyAge
            'Key1LastUsedDays' = $key1LastUsedDays
            'Key1KeyLastUsedDate' = $key1KeyLastUsedDate
            'Key1KeyLastUsedRegion' = $key1KeyLastUsedRegion
            'Key1KeyLastUsedServiceName' = $key1KeyLastUsedServiceName
            'Key2Id' = $key2Id
            'Key2Status' = $key2Status
            'Key2CreateDate' = $key2CreateDate
            'Key2KeyAge' = $key2KeyAge
            'Key2LastUsedDays' = $key2LastUsedDays
            'Key2KeyLastUsedDate' = $key2KeyLastUsedDate
            'Key2KeyLastUsedRegion' = $key2KeyLastUsedRegion
            'Key2KeyLastUsedServiceName' = $key2KeyLastUsedServiceName
        } | Select-Object UserPath,UserName,CreateDate,PasswordAge,PasswordLastUsed,PasswordLastUsedDays,MFA,  `
            Key1Id,Key1Status,Key1CreateDate,Key1KeyAge,Key1KeyLastUsedDate,Key1KeyLastUsedRegion,Key1KeyLastUsedServiceName,  `
            Key2Id,Key2Status,Key2CreateDate,Key2KeyAge,Key2KeyLastUsedDate,Key2KeyLastUsedRegion,Key2KeyLastUsedServiceName
            | Export-Csv -Path "$($path)awsinventory_iamusers_password_mfa_keys_$($date).csv" -Encoding ascii -NoTypeInformation -Append -Force
        
        # IAM Users Group Membership
        foreach ($group in ((Get-IAMGroupForUser -UserName $user.UserName))) {
            New-Object -TypeName PSObject -Property @{
                'AccountName' = $accname
                'AccountId' = $accid
                'UserPath' = $user.Path
                'UserName' = $user.UserName
                'Group' = $group.GroupName
            } | Select-Object UserPath,UserName,Group | Export-Csv -Path "$($path)awsinventory_iamusers_groups_$($date).csv" -Encoding ascii -NoTypeInformation -Append -Force
        }
    }

    Write-Host
    Write-Host "Gathering Route53 Resources"
    Write-Host
    # Route53 Resources
    foreach ($hostedzone in Get-R53HostedZoneList){
        # R53 Record Sets
        foreach ($recordset in (Get-R53ResourceRecordSet -Id $hostedzone.Id).ResourceRecordSets){
            New-Object -TypeName PSObject -Property @{
                'AccountName' = $accname
                'AccountId' = $accid
                'ZoneId' = $hostedzone.Id
                'HostedZoneName' = $hostedzone.Name
                'PrivateZone' = $hostedzone.Config.PrivateZone
                'RecordSetName' = $recordset.Name
                'RecordSetType' = $recordset.Type
            } | Select-Object AccountName,AccountId,ZoneId,HostedZoneName,PrivateZone,RecordSetName,RecordSetType  `
                | Export-Csv -Path "$($path)awsinventory_r53recordsets_$($date).csv" -Encoding ascii -NoTypeInformation -Append -Force
        }
        # R53 Hosted Zones
        New-Object -TypeName PSObject -Property @{
            'AccountName' = $accname
            'AccountId' = $accid
            'ZoneId' = $hostedzone.Id
            'HostedZoneName' = $hostedzone.Name
            'PrivateZone' = $hostedzone.Config.PrivateZone
        } | Select-Object AccountName,AccountId,ZoneId,HostedZoneName,PrivateZone | Export-Csv -Path "$($path)awsinventory_r53hostedzones_$($date).csv" -Encoding ascii -NoTypeInformation -Append -Force

    }

}

# Uncomment the following block to cleanup all profiles that have been created

<#
Get-AWSCredential -ListProfileDetail

foreach ($profile in (Get-AWSCredential -ListProfileDetail)) {
    if ($profile.ProfileName -ne 'default') {
        Remove-AWSCredentialProfile -ProfileName $profile.ProfileName -Confirm:$false
    }
}
#>
