resource "aws_instance" "gitlab" {
  ami                         = var.gitlab_ami
  instance_type               = var.gitlab_instance_type
  key_name                    = var.gitlab_key_name
  vpc_security_group_ids      = [aws_security_group.gitlab_sg.id]
  subnet_id                   = var.gitlab_subnet_id

  root_block_device {
    volume_type = "gp2"
    volume_size = "30"
  }

  tags = merge(
    {
      Name = "${var.base_name}-gitlab"
    },
    var.tags
  )

  volume_tags = merge(
    {
      Name = "${var.base_name}-gitlab-ebs"
    },
    var.tags
  )

}

resource "aws_eip" "gitlab" {
  instance = aws_instance.gitlab.id
  vpc = true

  tags = merge(
    {
      Name = "${var.base_name}-gitlab-eip"
    },
    var.tags
  )
}
