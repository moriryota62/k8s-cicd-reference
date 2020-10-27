provider "aws" {
  version = "~> 2.68.0"
  region  = "ap-northeast-1"
}

locals {
  k8s_vpc_id              = "vpc-b9eabcd1"               # EKSが動いているVPC ID
  k8s_public_subent_1_id  = "subnet-0a0de5bcc9682ac1a"   # EKSが所属するパブリックサブネット
  k8s_public_subent_2_id  = "subnet-0aba569fb29dce775"   # EKSが所属するパブリックサブネット
  k8s_private_subnet_1_id = "subnet-0d03268f1f9646f51"   # EKSが所属するプライベートサブネット
  k8s_private_subnet_2_id = "subnet-08453ccc9dfb19c69"   # EKSが所属するプライベートサブネット
  k8s_route_id            = "rtb-0b8e3edf0e8229608"      # EKSサブネットのルートテーブルID
  k8s_worker_sg_id        = "sg-04e357eb3d8e542cb"       # EKSワーカーノードのSG

  tags   = {
      pj     = "k8s-cicd"
      ownner = "mori"
  }
}

data "aws_caller_identity" "self" { }

module "gitlab" {
  source = "./gitlab"

  base_name        = "k8s-cicd"
  gitlab_subnet_id = local.k8s_public_subent_1_id
  gitlab_key_name  = "mori"
  gitlab_vpc_id    = local.k8s_vpc_id
  k8s_worker_sg_id = local.k8s_worker_sg_id
  account_id       = data.aws_caller_identity.self.account_id
  tags             = local.tags
}

module "ecr" {
  source = "./ecr"

  ecr_repositories = [
    "test",
    "test-app"
  ]

  vpc_id             = local.k8s_vpc_id
  subnet_ids         = [local.k8s_private_subnet_1_id,local.k8s_private_subnet_2_id]
  route_table_id     = local.k8s_route_id
  private_access_sgs = [module.gitlab.gitlab_sg,local.k8s_worker_sg_id]

  tags  = local.tags
}