# 自動スケジュール設定
# SSM Automation用のIAM Role
data "aws_iam_policy_document" "gitlab_ssm_automation_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "gitlab_ssm_automation" {
  name               = "GitLabSSMautomation"
  assume_role_policy = data.aws_iam_policy_document.gitlab_ssm_automation_trust.json
}

# SSM Automation用のIAM RoleにPolicy付与
resource "aws_iam_role_policy_attachment" "ssm-automation-atach-policy" {
  role       = aws_iam_role.gitlab_ssm_automation.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"
}

# CloudWatchイベント用のIAM Role
data "aws_iam_policy_document" "event_invoke_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "event_invoke_assume_role" {
  name               = "GitLabCloudWatchEventRole"
  assume_role_policy = data.aws_iam_policy_document.event_invoke_assume_role.json
}

# CloudWatchイベント用のIAM RoleにPolicy付与
data "aws_caller_identity" "self" {}

data "aws_iam_policy_document" "event_invoke_policy" {
  statement {
    effect  = "Allow"
    actions = ["ssm:StartAutomationExecution"]
    resources = [
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.self.account_id}:automation-definition/AWS-StartEC2Instance:*",
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.self.account_id}:automation-definition/AWS-StopEC2Instance:*",
    ]
  }
  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.gitlab_ssm_automation.arn]

    condition {
      test     = "StringLikeIfExists"
      variable = "iam:PassedToService"
      values   = ["ssm.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "event_invoke_policy" {
  name   = "testCloudWatchEventPolicy"
  role   = aws_iam_role.event_invoke_assume_role.id
  policy = data.aws_iam_policy_document.event_invoke_policy.json
}
