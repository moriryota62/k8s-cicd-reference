variable "tags" {
  description = "リソース群に付与する共通タグ"
  type        = map(string)
}

variable "ecr_repositories" {
  description = "作成するECRリポジトリ名のリスト"
  type        = list(string)
}

variable "vpc_id" {
  description = "ECRとプライベートリンクするVPCのID"
  type        = string
}

variable "subnet_ids" {
  description = "ECRとプライベートリンクするサブネットのID"
  type        = list(string)
}

variable "route_table_id" {
  description = "ECRとプライベートリンクするVPCのルートテーブル"
  type        = string
}

variable "private_access_sgs" {
  description = "ECRとプライベートリンクするSGのリスト"
  type        = list(string)
}