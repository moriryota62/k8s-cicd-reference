Flux関連のK8sマニフェストサンプルです。

**flux.yaml** 開発環境を想定したマニフェストです。flux-sshのマウント設定も記述しています。  
**flux-stg.yaml** ステージング環境を想定したマニフェストです。開発との差分はターゲットのブランチがstagingになっている点です。  
**flux-ssh.yaml** gitlabにアクセスするためのssh設定です。Fluxにマウントさせます。
