k8sマニフェストおよびOPAのポリシーのサンプルです。

### k8sマニフェスト
**gitlab-runner.yaml** helmで作成したgitlab-runnnerのサンプルマニフェストです。
**test.yaml**  CICD動作確認用のサンプルマニフェストです。

### OPAポリシー
**policy/dev/resource.rego** resourcesの設定をチェックするポリシーです。
**policy/stg/resource.rego** resourcesの設定をチェックするポリシーです。devと内容は同じです。
**policy/stg/resource.rego** probeの設定をチェックするポリシーです。
