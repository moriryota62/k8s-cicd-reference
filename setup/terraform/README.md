# Terraformモジュール

**K8sCICD用 GitLab**

K8sCICDのGitレポジトリとして使用するGitLabをEC2インスタンスで作成するTerraformです。以下の特徴があります。

- AMIはGitLabがmarketplaceで公開しているAMIを使用します。
- EC2インスタンスに付与するKey-pairは事前に用意しものを使用します。
- デフォルトでは以下スペックでEC2インスタンスを作成します。
  - インタスンスタイプ: t2.medium
  - ディスク: 30GB
- VPC、K8sは別途デプロイ済みの前提です。
- GitLab用EC2インスタンスにはEIPを割り当てます。
- GitLab用EC2インスタンスのインバウンドは以下が許可されます。
  - TISネットワーク（210.148.59.64/28）
  - K8s worker
- K8s workerのセキュリティグループを指定してください。
- 他のネットワークからのアクセス（たとえば、社外の作業端末）する場合はインバウンドを修正してください。
- GitLab用EC2インスタンスは日本時間の平日9-19時で自動起動するスケジュールを設定します。
- GitLab用EC2インスタンスのディスクは日本時間の毎日24時に自動スナップショットを取得します。

**ECR**

CICDで作成するコンテナイメージを格納するECRを作成するTerraformです。以下の特徴があります。

- 同じイメージタグの作成を抑制するイミュータビリティは無効で作成します。
- イメージプッシュ時の自動スキャンを有効にして作成します。

# モジュールパラメータ

**K8sCICD用 GitLab**

|パラメータ名|説明|デフォルト値|必須|
|-|-|-|-|
|base_name|リソースに付ける接頭語|-|★|
|region|AWSのリージョン|ap-northeast-1|-|
|gitlab_ami|GitLabのAMI|ami-07c9e77157292bfc4|-|
|gitlab_instance_type|インスタンスタイプ|t2.medium|-|
|gitlab_subnet_id|EC2インタンスを配置するサブネット|-|★|
|gitlab_key_name|EC2インタスンスのキー|-|★|
|gitlab_vpc_id|EC2インタンスを配置するVPC|-|★|
|k8s_worker_sg_id|K8s workerのSG|-|★|
|account_id|AWSアカウントのID|-|★|
|tags|リソースに付けるタグ|-|★|

**ECR**

|パラメータ名|説明|デフォルト値|必須|
|-|-|-|-|
|ecr_repositories|ECRリポジトリ名の一覧|-|★|
|vpc_id|ECRとプライベートアクセスするVPC|-|★|
|subnet_ids|ECRとプライベートアクセスするサブネット|-|★|
|route_table_id|ECRとプライベートアクセスするサブネットのルートテーブル|-|★|
|private_access_sgs|ECRとプライベートアクセスするセキュリティグループ|-|★|
|tags|リソースに付けるタグ|-|★|

## 使い方
1. main.tfの必須パラメータを入力します。（あらかじめ設定例を記入しています）
2. main.tfがあるディレクトリで以下コマンドを実行します。
   ```sh
   terraform init
   ```
3. initが成功したらplanします。
   ```sh
   terraform plan
   ```
4. planの結果を確認し、想定通りのリソースが作成されることを確認します。
5. applyします、
   ``` sh
   terraform apply
   > yes
   ```