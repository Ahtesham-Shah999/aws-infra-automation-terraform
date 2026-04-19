# ─────────────────────────────────────────────────────────────────────────────
# Task 4 — CloudWatch Alarms for Auto Scaling
# Member: 22F-3677
# ─────────────────────────────────────────────────────────────────────────────

# ── Scale-Out Alarm: CPU >= 60% for 2 consecutive 60-second periods ───────────
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 60
  alarm_description   = "Scale OUT: avg CPU >= 60% for 2 consecutive minutes"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_autoscaling_policy.scale_out.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  tags = {
    Name = "${var.project_name}-cpu-high-alarm"
  }
}

# ── Scale-In Alarm: CPU <= 20% for 2 consecutive 60-second periods ────────────
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.project_name}-cpu-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 20
  alarm_description   = "Scale IN: avg CPU <= 20% for 2 consecutive minutes"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_autoscaling_policy.scale_in.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  tags = {
    Name = "${var.project_name}-cpu-low-alarm"
  }
}
