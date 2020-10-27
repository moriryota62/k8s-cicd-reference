resource "aws_dlm_lifecycle_policy" "dlm-lifecycle-policy-gitlab" {
    description        = "daily_ebs_snapshot_gitlab"
    execution_role_arn = "arn:aws:iam::${var.account_id}:role/service-role/AWSDataLifecycleManagerDefaultRole"
    state              = "ENABLED"

    policy_details {
        resource_types = ["VOLUME"]
        schedule {
        name = "daily_snapshots_gitlab"
        create_rule {
            interval      = 24
            interval_unit = "HOURS"
            times         = ["15:00"]
            }
        retain_rule {
            count = 1
            }  
        copy_tags = true
        }
        target_tags = {
        Name = "${var.base_name}-gitlab-ebs"
        }
    }   
}
