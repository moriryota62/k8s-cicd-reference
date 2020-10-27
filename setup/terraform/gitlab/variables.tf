variable "base_name" {
}

variable "tags" {
  description = "リソース群に付与する共通タグ"
  type        = map(string)
}

variable "region" {
  default = "ap-northeast-1"
}

variable "gitlab_ami" {
  default = "ami-07c9e77157292bfc4"
}

variable "gitlab_instance_type" {
  default = "t2.medium"
}

variable "gitlab_subnet_id" {
}

variable "gitlab_key_name" {
}

variable "gitlab_vpc_id" {
}

variable "k8s_worker_sg_id" {
}

variable "account_id" {
}