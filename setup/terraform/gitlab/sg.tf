resource "aws_security_group" "gitlab_sg" {
  name        = "${var.base_name}-gitlab-sg"
  description = "for gitlab"

  tags = merge(
    {
      Name = "${var.base_name}-gitlab-sg"
    },
    var.tags
  )

  vpc_id = var.gitlab_vpc_id

  ingress {
    description = "allow any from k8s"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    
    security_groups = [var.k8s_worker_sg_id]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["210.148.59.64/28"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["210.148.59.64/28"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
