resource "aws_vpc_endpoint" "ecr-api" {
  service_name      = "com.amazonaws.ap-northeast-1.ecr.api"
  vpc_endpoint_type = "Interface"
  vpc_id            = var.vpc_id
  subnet_ids        = var.subnet_ids

  security_group_ids = [
    "${aws_security_group.ecr.id}",
  ]

  private_dns_enabled = true

  tags = merge(
    {
      "Name" = "ecr-api"
    },
    var.tags
  )
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  service_name      = "com.amazonaws.ap-northeast-1.ecr.dkr"
  vpc_endpoint_type = "Interface"
  vpc_id            = var.vpc_id
  subnet_ids        = var.subnet_ids

  security_group_ids = [
    "${aws_security_group.ecr.id}",
  ]

  private_dns_enabled = true

  tags = merge(
    {
      "Name" = "ecr-dkr"
    },
    var.tags
  )
}

resource "aws_vpc_endpoint" "ecr_s3" {
  vpc_id          = var.vpc_id
  service_name    = "com.amazonaws.ap-northeast-1.s3"
  route_table_ids = [var.route_table_id]

  tags = merge(
    {
      "Name" = "ecr-s3"
    },
    var.tags
  )
}
