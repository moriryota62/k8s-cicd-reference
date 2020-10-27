# CloudWatchイベント - EC2の定時起動
resource "aws_cloudwatch_event_rule" "start_gitlab_rule" {
  name                = "${var.base_name}-StartInstanceRule"
  description         = "Start instances"
  schedule_expression = "cron(0 0 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_target" "start_gitlab" {
  target_id = "StartInstanceTarget"
  arn       = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.self.account_id}:automation-definition/AWS-StartEC2Instance"
  rule      = aws_cloudwatch_event_rule.start_gitlab_rule.name
  role_arn  = aws_iam_role.event_invoke_assume_role.arn

  input = <<DOC
{
  "InstanceId": ["${aws_instance.gitlab.id}"],
  "AutomationAssumeRole": ["${aws_iam_role.gitlab_ssm_automation.arn}"]
}
DOC
}

# CloudWatchイベント - EC2の定時停止
resource "aws_cloudwatch_event_rule" "stop_gitlab_rule" {
  name                = "${var.base_name}-StopInstanceRule"
  description         = "Stop instances"
  schedule_expression = "cron(0 10 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_target" "stop-gitlab" {
  target_id = "StopInstanceTarget"
  arn       = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.self.account_id}:automation-definition/AWS-StopEC2Instance"
  rule      = aws_cloudwatch_event_rule.stop_gitlab_rule.name
  role_arn  = aws_iam_role.event_invoke_assume_role.arn

  input = <<DOC
{
  "InstanceId": ["${aws_instance.gitlab.id}"],
  "AutomationAssumeRole": ["${aws_iam_role.gitlab_ssm_automation.arn}"]
}
DOC
}