# This is a Powershell script to set a retention period for CloudWatch Logs log groups
# Created and maintained by: Willer Pulis
# If you are using AWS CloudShell, enter the Powershell environment by running the command "pwsh"
# Then run the two following commands:
# Install-Module AWSPowerShell
# Import-Module AWSPowerShell
######################################################################
#
# DON'T FORGET TO SET THE RETENTION PERIOD ON THE $retention VARIABLE
#
######################################################################

Set-DefaultAWSRegion us-east-1

# Set the retention for all CW Logs log groups
$retention=

# Generate list of CW Logs log groups prior to setting the retention
$date=get-date -Format yyyy-MM-dd-HHmmss
(Get-EC2Region).RegionName | ForEach-Object {
    $region = $_
    Write-Host "Gathering CW Logs log groups for region $_"
    (Get-CWLLogGroup -Region $region) | ForEach-Object {
        New-Object -TypeName PSObject -Property @{
            'Region' = $region
            'LogGroupName' = $_.LogGroupName
            'RetentionInDays' = $_.RetentionInDays
            'StoredBytes' = $_.StoredBytes
            'CreationTime' = $_.CreationTime
        }
    } | Select-Object Region,LogGroupName,RetentionInDays,StoredBytes,CreationTime `
        | Export-Csv -Path "cwlogs_log_groups_$($date).csv" -Encoding ascii -NoTypeInformation -Append -Force
}

# Setting the retention for all CW Logs log groups
(Get-EC2Region).RegionName | ForEach-Object {
    $region = $_
    Write-Host "Region $_"
    (Get-CWLLogGroup -Region $region) | ForEach-Object {
        Write-CWLRetentionPolicy -Region $region -LogGroupName $_.LogGroupName -RetentionInDays $retention
    }
}

# Generate list of CW Logs log groups after setting the retention
$date=get-date -Format yyyy-MM-dd-HHmmss
(Get-EC2Region).RegionName | ForEach-Object {
    $region = $_
    Write-Host "Gathering CW Logs log groups for region $_"
    (Get-CWLLogGroup -Region $region) | ForEach-Object {
        New-Object -TypeName PSObject -Property @{
            'Region' = $region
            'LogGroupName' = $_.LogGroupName
            'RetentionInDays' = $_.RetentionInDays
            'StoredBytes' = $_.StoredBytes
            'CreationTime' = $_.CreationTime
        }
    } | Select-Object Region,LogGroupName,RetentionInDays,StoredBytes,CreationTime `
        | Export-Csv -Path "cwlogs_log_groups_$($date).csv" -Encoding ascii -NoTypeInformation -Append -Force
}
