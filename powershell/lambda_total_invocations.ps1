# Installing and Importing the AWSPowerShell PS module
Install-Module AWSPowerShell
Import-Module AWSPowerShell

### Setting MetricDataQuery values
# Labels
$MDQ = [Amazon.CloudWatch.Model.MetricDataQuery]::new()
$MDQ.Id = 'lambdaInvocations'
$MDQ.Label = 'LambdaInvocations'

# Metric stat and period
$MDQMetricStat = [Amazon.CloudWatch.Model.MetricStat]::new()
$MDQMetricStat.Stat = 'Sum'
$MDQMetricStat.Period = 3600

# Metric name and namesspace
$MDQMetricStatMetric = [Amazon.CloudWatch.Model.Metric]::new()
$MDQMetricStatMetric.MetricName = 'Invocations'
$MDQMetricStatMetric.Namespace = 'AWS/Lambda'

# Metric Dimension - Comment the 4th line of this section if not applicable
$MDQMetricStatMetricDimension = [Amazon.CloudWatch.Model.Dimension]::new()
$MDQMetricStatMetricDimension.Name = 'InstanceId'
$MDQMetricStatMetricDimension.Value = '<instance-id>'
#$MDQMetricStatMetric.Dimensions = $MDQMetricStatMetricDimension

$MDQMetricStat.Metric = $MDQMetricStatMetric
$MDQ.MetricStat = $MDQMetricStat

# Setting start and end date/time
$StartTime = Get-Date -Date "2021-01-01 00:00:00Z"
$EndTime = Get-Date -Date "2021-02-01 00:00:00Z"

$sumOfInvocations = 0

(Get-EC2Region -Region us-east-1).RegionName | ForEach-Object {
    $region = $_
    $lambdametrics = Get-CWMetricData -Region $region -ScanBy 'TimestampAscending' `
    -UtcStartTime $StartTime -UtcEndTime $EndTime -MetricDataQuery $MDQ

    $lambdametrics.MetricDataResults.Values | ForEach-Object {
        $sumOfInvocations+=$_
    }
}

# Printing sum
$sumOfInvocations