output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic"
  value       = aws_sns_topic.alerts.name
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "alarm_arns" {
  description = "ARNs of all CloudWatch alarms"
  value = {
    asg_cpu_high      = aws_cloudwatch_metric_alarm.asg_cpu_high.arn
    alb_unhealthy     = aws_cloudwatch_metric_alarm.alb_unhealthy_hosts.arn
    alb_healthy_low   = aws_cloudwatch_metric_alarm.alb_healthy_hosts_low.arn
    alb_5xx           = aws_cloudwatch_metric_alarm.alb_5xx_errors.arn
    alb_response_time = aws_cloudwatch_metric_alarm.alb_response_time.arn
    rds_cpu_high      = aws_cloudwatch_metric_alarm.rds_cpu_high.arn
    rds_storage_low   = aws_cloudwatch_metric_alarm.rds_storage_low.arn
  }
}

output "alarm_names" {
  description = "Names of all CloudWatch alarms"
  value = [
    aws_cloudwatch_metric_alarm.asg_cpu_high.alarm_name,
    aws_cloudwatch_metric_alarm.alb_unhealthy_hosts.alarm_name,
    aws_cloudwatch_metric_alarm.alb_healthy_hosts_low.alarm_name,
    aws_cloudwatch_metric_alarm.alb_5xx_errors.alarm_name,
    aws_cloudwatch_metric_alarm.alb_response_time.alarm_name,
    aws_cloudwatch_metric_alarm.rds_cpu_high.alarm_name,
    aws_cloudwatch_metric_alarm.rds_storage_low.alarm_name,
  ]
}
