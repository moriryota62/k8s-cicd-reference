resource "aws_ecr_repository" "this" {
  for_each = toset(var.ecr_repositories)

  name  = each.value

  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(
    {
      "Name" = each.value
    },
    var.tags
  )
}
