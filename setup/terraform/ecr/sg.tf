resource "aws_security_group" "ecr" {
  name        = "ecr-privatelink"
  description = "ECR PrivateLink security group"

  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = toset(var.private_access_sgs)

    content {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      security_groups = [ingress.value]
    }
  }

  tags = merge(
    {
      "Name" = "ecr-privatelink-sg"
    },
    var.tags
  )
}