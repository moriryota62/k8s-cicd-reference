- [環境構築](#環境構築)
- [1. GitLab、ECRの構築](#1-gitlabecrの構築)
  - [GitLabのデプロイ](#gitlabのデプロイ)
  - [ECRのデプロイ](#ecrのデプロイ)
- [2. GitLab CICDのセットアップ](#2-gitlab-cicdのセットアップ)
  - [GitLabの初期設定](#gitlabの初期設定)
  - [GitLbaの公開URLの変更](#gitlbaの公開urlの変更)
  - [GitLab Runnerの登録情報確認](#gitlab-runnerの登録情報確認)
  - [GitLab Runnerのデプロイ](#gitlab-runnerのデプロイ)
- [3. GitLab CICDパイプラインの定義](#3-gitlab-cicdパイプラインの定義)
  - [Gitレポジトリの作成](#gitレポジトリの作成)
  - [サンプルアプリの作成](#サンプルアプリの作成)
  - [.gitlab-ci.yamlの作成](#gitlab-ciyamlの作成)
  - [パイプライン実行](#パイプライン実行)
- [4. Fluxのセットアップ](#4-fluxのセットアップ)
  - [k8sマニフェストの作成](#k8sマニフェストの作成)
  - [GitLab SSHキー設定](#gitlab-sshキー設定)
  - [Fluxマニフェストの生成](#fluxマニフェストの生成)
  - [FluxのSSH設定](#fluxのssh設定)
  - [Fluxマニフェストの修正・デプロイ](#fluxマニフェストの修正デプロイ)
  - [イメージ更新時の自動デプロイ設定](#イメージ更新時の自動デプロイ設定)
- [5. OPA ポリシーチェック](#5-opa-ポリシーチェック)
  - [チェックポリシーの作成](#チェックポリシーの作成)
  - [マニフェストのCI](#マニフェストのci)
- [6. ステージング環境のセットアップ](#6-ステージング環境のセットアップ)
  - [K8sレポジトリにStg用ブランチを作成](#k8sレポジトリにstg用ブランチを作成)
  - [Fluxのデプロイ](#fluxのデプロイ)
  - [ステージング用のポリシー作成](#ステージング用のポリシー作成)
  - [ステージング用のCI追加](#ステージング用のci追加)
  - [ステージングへのデプロイ](#ステージングへのデプロイ)

# 環境構築

今回のCICD環境を準備するには以下を構築します。なお、ECRやEKSはすでに作らている前提です。また、本手順はGitやKubernetesなどの操作に慣れている人を対象に記載しています。

1. [GitLab、ECRの構築](#1-gitlabecrの構築)
2. [GitLab CICDのセットアップ](#2-gitlab-cicdのセットアップ)
3. [GitLab CICDパイプラインの定義](#3-gitlab-cicdパイプラインの定義)
4. [Fluxのセットアップ](#4-fluxのセットアップ)
5. [OPA ポリシーチェック](#5-opa-ポリシーチェック)
6. [ステージング環境のセットアップ](#6-ステージング環境のセットアップ)

1,2はアプリ、インフラともに共通のCICD環境のセットアップです。  
3はアプリCICDのセットアップです。  
4はアプリ、インフラ共通のデプロイのセットアップです。
5、6はインフラCICDのセットアップです。

順番に構築手順を解説します。

# 1. GitLab、ECRの構築

## GitLabのデプロイ
まず、AWS上にプライベートなGitLabサーバを構築します。GitLabサーバの構築はmarketplaceにあるGitLabより提供されいているAMIを使用すると楽です。たとえば[このAMI](https://aws.amazon.com/marketplace/pp/B071RFCJZK?ref=cns_1clkPro)です。なお、[このAMI](https://aws.amazon.com/marketplace/pp/B071RFCJZK?ref=cns_1clkPro)を使用する場合、marketplaceを通じてサブスクライブする必要があります。（ライセンス費用は発生せず、規約の同意だけです。）AMIを使いインスタンスをデプロイする際にマシンタイプやディスクサイズを指定してください。（検証時はt2.mediam、50GBで作成しました。）また、作業端末などAWS外からもアクセスしたいため、パブリックサブネットにデプロイするのが良いと思います。あわせてGitLab用にEIPを確保し、Route 53で名前解決できるようにすると良いと思います。

GitLabの構築には次のTerraformも活用ください。[GitLab Terraform サンプル](./terraform)

## ECRのデプロイ
コンテナイメージを格納するECRレポジトリを作成します。AWS環境内に閉じてECRを使う場合、プライベートリンクで繋いだ方がインターネットに出ないのでセキュリティ的に良いです。

ECRの構築には次のTerraformも活用ください。[ECR Terraform サンプル](./terraform)

# 2. GitLab CICDのセットアップ

## GitLabの初期設定
デプロイしたGitLabにログインします。マネジメントコンソールなどで作成したGitLabのパブリックDNS名を確認します。（Route53にドメイン登録していればそのドメイン名を確認します。）WEBブラウザに確認したパブリックDNS名を入力し、GitLabのGUIに接続します。初回アクセス時にrootのパスワードを設定します。もし接続できない場合は以下を確認してください。

- 接続先があっているか確認。また、社内からだとIPアドレスでは接続できないはずなのでちゃんとドメイン名を指定する。
- GitLabに付与されたセキュリテーグループでソースIPおよびポート（80,443）が許可されいるか確認する。

## GitLbaの公開URLの変更
httpやsshでレポジトリをクローンできるように、GitLabの公開URLを変更します。GitLabにsshでログインします。AMIで構成したGitLabの場合は``ubuntu``ユーザでログインします。

以下コマンドで``/etc/gitlab/gitlab.rb``を修正します。
``` sh
sudo vi /etc/gitlab/gitlab.rb
```
```
【修正パラメータ例】
external_url 'http://ec2-54-150-231-247.ap-northeast-1.compute.amazonaws.com'  # 外部からアクセスできるGitLabサーバのDNS名に修正
unicorn['worker_timeout'] 600                                                  # 600などtimeout時間を十分長くする
```

上記修正したらGitLabを再構成して起動しなおします。
``` sh
sudo gitlab-ctl reconfigure
sudo gitlab-ctl restart
```

## GitLab Runnerの登録情報確認
GitLabにwebブラウザからアクセスしrootでログインします。admin area（画面上部のスパナマーク） -> Overview -> Runners を表示する。``Set up a shared Runner manually``に表示される``token``を控えておく。（GitLab Runnerのデプロイで使用する。）

## GitLab Runnerのデプロイ
GitLab CICDはレポジトリに変更が発生するとCICDのパイプラインが動き出します。レポジトリの変更を検知するのがGitLab Runnerです。GitLab RunnerはGitLab本体とは別の場所に建てることが多いです。これはGitLab自体に不必要な権限を与えない様にするためです。（もしGitLabでパイプラインを実行し変更をデプロイする様にするとGitLab自体に強い権限を渡す必要があります。GitLabは多くの場合外部からのアクセスを許可するため、万一乗っ取られた場合に被害が大きくなります。これを防ぐため、GitLab本体とRunnerを分離し、Runnnerの方には環境の変更を行える権限を与えます。）また、Runnerはパイプラインを実行する方法をexecuterで指定できます。executerにはshellやdocker、Kubernetesなどから選ぶことができます。

今回はKubernetes上にRunnerを構成し、Kubernetes executerを使用します。KubernetesへのインストールはHelm chertが用意されています。以下の手順ではHelmからマニフェストを生成してk8sへapplyしています。生成する[マニフェストのサンプル](./k8s/gitlab-runner.yaml)を配置していますのでhelmを使わずサンプルマニフェストを編集してapplyしても良いです。その場合、secret:gitlab-runner-gitlab-runnerに設定する``runner-registration-token``は以下コマンドの様に改行なしのbase64エンコードした値にするのを忘れずに行いましょう。
``` sh
echo -n {トークン} | base64
```

以下コマンドでGitLabのchartレポジトリを登録します。
``` sh
helm repo add gitlab https://charts.gitlab.io
```

GitLba Runnerのレポジトリが見えることを確認する。
``` sh
helm search repo gitlab/gitlab-runner
```
```
【出力例】
NAME                	CHART VERSION	APP VERSION	DESCRIPTION
gitlab/gitlab-runner	0.20.0       	13.3.0     	GitLab Runner
```

values.yamlを作成する。values.yamlの元ネタは[公式の例](https://docs.gitlab.com/runner/install/kubernetes.html#additional-configuration)を参考にする。とくに以下の点を修正する。
- ``gitlabUrl``にk8sから到達可能なGitLabのURLを設定
- ``runnerRegistrationToken``に[GitLab Runnerの登録情報確認](#gitlab-runnerの登録情報確認)で確認した``token``を設定
- rbac.createをtrueにする
- docker buildなど特権が必要な操作もしたいためrunner.privilegedをtrue
- runnerを識別できるようにrunner.tagsに任意の値を設定する。（ここで設定した値は後ほどgitlab-ci.ymlを書く時に使います。）
修正した[values.yamlのサンプル](./gitlab/values.yaml)もあるため参考にしてください。

``` sh
cat <<EOF >values.yaml
gitlabUrl: http://ec2-54-150-231-247.ap-northeast-1.compute.amazonaws.com
runnerRegistrationToken: "CzYp_yitXSdvoHkJmdxY"
concurrent: 10
checkInterval: 30
rbac:
  create: true
  clusterWideAccess: true
runners:
  image: ubuntu:18.04
  privileged: true
  tags: "k8s"
  builds:
    cpuLimit: 200m
    memoryLimit: 256Mi
    cpuRequests: 100m
    memoryRequests: 128Mi
  services:
    cpuLimit: 200m
    memoryLimit: 256Mi
    cpuRequests: 100m
    memoryRequests: 128Mi
  helpers:
    cpuLimit: 200m
    memoryLimit: 256Mi
    cpuRequests: 100m
    memoryRequests: 128Mi
EOF
```

``helm install``でインストールする、なお、今回はHelmで直接インストールはせず、``--dry-run``でマニフェストを生成し、マニフェストをapplyしてデプロイする。
``` sh
helm install gitlab-runner -f values.yaml gitlab/gitlab-runner --dry-run > gitlab-runner.yaml
```

このままだと前後に不要な情報やタグが含まれるため整形する。なお、整形済みのマニフェスト例は[参考](./k8s/gitlba-runner.yaml)を参照ください。
``` sh
vi gitlab-runner.yaml
```

整形したマニフェストをk8sにデプロイする。
``` sh
kubectl apply -f gitlab-runner.yaml
```

デプロイ確認
``` sh
kubectl get pod
```
```
【出力例】
NAME                                           READY   STATUS    RESTARTS   AGE
gitlab-runner-gitlab-runner-7fb7fdcc85-zsl97   1/1     Running   0          52s
```

admin area（画面上部のスパナマーク） -> Overview -> Runners を表示する。上記デプロイしたRunnerが表示されること。（もし表示されない場合、K8sにデプロイしたgitlab-ruunerのpodを確認してください。ログになにかヒントがあるかもしれません。）

# 3. GitLab CICDパイプラインの定義

## Gitレポジトリの作成
GitLab CICDは各レポジトリごとに設定します。CICDテスト用にレポジトリを作成します。レポジトリは好きなユーザ/グループで作成してください。例ではAdministrator(root)でtestレポジトリを作成して進めます。

また、作成したレポジトリで Settings -> CI/CD -> Runners を表示し、``Available shared Runners``にRunnerが登録されていることを確認します。

## サンプルアプリの作成
作成したレポジトリにサンプルアプリを保存します。このレポジトリにはDockerでbuildするのに必要な素材一式とDockerfileを格納します。今回はテスト様にnginxをベースイメージとし、簡単に編集したindex.htmlを埋め込みます。なお、作成するファイル群は[サンプル](./test)を用意していますので、この内容をコピーしても良いです。

まずは適当なディレクトリに作成したレポジトリをクローンして移動してください。以下、例です。
``` sh
git clone git clone http://ec2-54-150-231-247.ap-northeast-1.compute.amazonaws.com/root/test.git
cd test
```

以下のようなコマンドで適当な``index.html``を作成します。
``` sh
echo "cicd test v1" > index.html
```

以下のようなコマンドでnginxをベースイメージにしたコンテナイメージをビルドする``Dockerfile``を作成します。
``` sh
cat <<EOF > Dockerfile
FROM nginx:1.19.2
COPY index.html /usr/share/nginx/html/index.html
EOF
```

``index.html``と``Dockerfile``を作成したらリモートレポジトリに変更をプッシュします。ビルドはGitLab CICDで行うため手動では不要です。
``` sh
git add .
git commit -m "init commit"
git push
```

## .gitlab-ci.yamlの作成
GitLab CICDのパイプライン設定を行う``.gitlab-ci.yml``を作成します。``.gitlab-ci.yml``はかならずレポジトリのルートに作成してください。``.gitlab-ci.yml``の書き方については[公式リファレンス](https://docs.gitlab.com/ee/ci/yaml/README.html)を参照ください。

以下内容の``gitlab-ci.yml``を作成します。``ECR_HOST``は使用しているAWSアカウントIDに修正してください。また、以下のパイプラインではイメージ名を``Gitレポジトリ名:ビルド時の時刻``で作成します。あらかじめECRに``Gitレポジトリ名``と同じ名前のレポジトリを作成しておいてください。

``` yaml
stages:
  - build

docker-build:
  image: 
    name: gcr.io/kaniko-project/executor:debug
    entrypoint: [""]
  stage: build
  variables:
    ECR_HOST: 456247443832.dkr.ecr.ap-northeast-1.amazonaws.com
  script:
    - BUILD_DATE=`date "+%Y-%m%d-%H%M"` 
    - |
          cat > /kaniko/.docker/config.json <<EOF
          {
            "credHelpers": {
              "${ECR_HOST}": "ecr-login"
            }
          }
          EOF
    - /kaniko/executor --context $CI_PROJECT_DIR --dockerfile $CI_PROJECT_DIR/Dockerfile --destination ${ECR_HOST}/$CI_PROJECT_NAME:$BUILD_DATE
  only:
    - master
  tags:
    - k8s
```

上記、パイプラインの内容を簡単に解説すると次の通りです。
- パイプラインには``build``のステージを定義
- ``docker-build``ジョブを``build``ステージで実行
- ``docker-build``ジョブは``gcr.io/kaniko-project/executor:debug``イメージを使って実行
- レポジトリのルートに配置されている``Dockerfile``を使ってコンテナをビルド
- イメージ名は``ECR_HOST/Gitレポジトリ名:ビルド時刻``
- ビルドしたイメージを``ECR_HOST``で指定したECRにプッシュ

なお、今回はコンテナをビルド&プッシュするジョブしか定義していませんが、アプリケーションのビルドやテストを行うステージを追加しジョブを設定すればアプリケーションのCIを実装することもできます。

## パイプライン実行

``gitlab-ci.yml``をリモートにプッシュします。
``` sh
git add .
git commit -m "gitlab-ci add"
git push
```

GitLabのレポジトリを確認します。CI/CD -> Pipelines を表示するとパイプラインが実行されていることが確認できるはずです。なお、ワーカーノードにECRへのFullAcessなどECRへの書き込み権限がないとパイプラインが失敗するため、IAMロールの付与を忘れずに行いましょう。

また、パイプライン実行完了後、ECRを確認すると新しいイメージがpushされているはずです。

# 4. Fluxのセットアップ
K8sへのデプロイツールであるFluxをセットアップします。Fluxには以下大きく2つの機能があります。両方の機能を使えるようにFluxを設定しK8sへデプロイします。
1. Gitレポジトリの変更発生時、マニフェストをK8sへ自動デプロイする
2. コンテナレポジトリの変更発生時、Gitレポジトリのマニフェストを自動で更新する（更新すると1の機能で自動デプロイされる）

## k8sマニフェストの作成
まずはK8sマニフェストを管理するレポジトリをGitLabに作成します。今回は``k8s``という名前のレポジトリで進めます。レポジトリを作成したら任意のディレクトリでクローンしてください。クローンしたレポジトリに以下のマニフェストファイルを作成してください。``image``は自身の環境にあわせて必ず修正してください。また、以下マニフェストはK8sのService Type:LBを使用しているため、applyするとCLBがK8sにより作成されます。（マニフェストのサンプルは[k8s](./k8s/test.yaml)にもあります。）

``` yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: test-nginx
  name: test-nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-nginx
  template:
    metadata:
      labels:
        app: test-nginx
    spec:
      containers:
      - image: 456247443832.dkr.ecr.ap-northeast-1.amazonaws.com/test:2020-0902-0554
        name: test
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: test-nginx
  name: test-nginx
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: test-nginx
  type: LoadBalancer
---
```

上記マニフェストを作成したらデプロイします。
``` sh
kubectl apply -f test.yaml
```

デプロイ確認します。
``` sh
kubectl get pod
```
```
【表示例】
NAME                                           READY   STATUS    RESTARTS   AGE
gitlab-runner-gitlab-runner-5cdb7bb65b-kzzvq   1/1     Running   0          124m
test-nginx-74b4579d84-skcls                    1/1     Running   0          33s
```
``` sh
kubectl get svc
```
```
【表示例】
NAME         TYPE           CLUSTER-IP       EXTERNAL-IP                                                                   PORT(S)        AGE
kubernetes   ClusterIP      172.20.0.1       <none>                                                                        443/TCP        3h20m
test-nginx   LoadBalancer   172.20.253.142   a11c6f23eecf011ea809a0ae5b357403-652431460.ap-northeast-1.elb.amazonaws.com   80:30916/TCP   22s
```

ServiceのEXTERNAL-IPに表示されるELBのDNS名をコピーし、ブラウザなどで接続確認します。``cicd test v1``と表示されることを確認してください。

確認がとれたらGitLabに変更をプッシュしてください。
``` sh
git add .
git commit -m "manifest initial add"
git push
```

## GitLab SSHキー設定
FluxからのGitレポジトリをクローンする際にSSHを使用します。そのため、あらかじめGitLabにSSHキーを設定します。

まずは作業端末でGitLabのSSHキーを以下コマンドで作成します。以下のコマンドでは鍵の名前を``cicd-gitlab``にしています。
``` sh
ssh-keygen -t rsa -b 4096
> Generating public/private rsa key pair.
> Enter file in which to save the key (/Users/moriryota62/.ssh/id_rsa): cicd-gitlab
> Enter passphrase (empty for no passphrase): {空エンター}
> Enter same passphrase again: {空エンター}
```

鍵の作成確認
``` sh
ll cicd-gitlab*
```
```
【表示例】
-rw-------  1 moriryota62  staff  3401  9  3 13:29 cicd-gitlab
-rw-r--r--  1 moriryota62  staff   753  9  3 13:29 cicd-gitlab.pub
```

``cicd-gitlab``と``cicd-gitlab.pub``の内容を表示します。この後の手順でこれらファイルの内容をコピーして貼り付けます。
``` sh
cat cicd-gitlab
cat cicd-gitlab.pub
```

GitLabにWEBブラウザからログインします。以下手順ではrootでログインしますが任意のユーザでも良いです。ログイン後、 画面右上のユーザアイコン -> Settings を表示します。左メニューのSSH Keysを表示します。Keyにさきほど表示した``cicd-gitlab.pub``の内容をすべて貼り付けます。有効期限は設定した方が良いですがしなくても設定できます。Add keyをクリックすると鍵が登録されます。

## Fluxマニフェストの生成
作業端末にFluxをコントロールするためのCLIツール``fluxctl``をインストールします。インストールの手順は[公式手順](https://docs.fluxcd.io/en/1.19.0/references/fluxctl/)に従い、自身の環境にあわせてインストールしてください。

fluxctlを使いFluxのマニフェストを生成します。Gitのユーザ名、メール、URLは自身の環境に合わせて変えてください。マニフェストのサンプルは[こちら](./flux/flux.yaml)にもあります。
``` sh
fluxctl install \
--git-user=root \
--git-email=root@cicd-test \
--git-url=git@ec2-34-239-122-135.compute-1.amazonaws.com:root/k8s.git \
> flux.yaml
```

## FluxのSSH設定
FluxからGttLabへのアクセスはSSHを使用します。そのため、FluxにSSHの設定をします。

一度作成した``flux.yaml``を使用してFluxをデプロイします。
``` sh
kubectl apply -f flux.yaml
kubectl get pod
```

pod:fluxにログインし、sshの設定を行います。
``` sh
kubectl exec -it {Flux Pod名} /bin/bash
```

FluxのPodにログインしたら以下コマンドでSSHの設定を行います。
``` sh
eval `ssh-agent`
mkdir ~/.ssh
vi ~/.ssh/cicd-gitlab # [GitLab SSHキー設定](#gitlab-sshキー設定)で作成したcicd-gitlabの内容をすべて貼り付けて保存
chmod 600 ~/.ssh/cicd-gitlab
ssh-add ~/.ssh/cicd-gitlab
ssh-keyscan ec2-54-199-98-109.ap-northeast-1.compute.amazonaws.com > ~/.ssh/known_hosts # ホスト名は自身の環境のGitLabに修正ください
cat <<EOF > ~/.ssh/config
host gitlab
  HostName ec2-54-199-98-109.ap-northeast-1.compute.amazonaws.com
  User git
  IdentityFile ~/.ssh/cicd-gitlab
  Port 22
EOF
# 上記、host、HostNameは環境にあわせて修正してください
```

上記設定したら``git clone``できるか確認します。GitLabに作成済の``k8s``レポのsshのclone URLを使用し、以下の様にクローンしてください。無事クローンできれば設定完了です。
``` sh
git clone git@ec2-54-199-98-109.ap-northeast-1.compute.amazonaws.com:root/k8s.git
```

しかし、これだとPod再作成されるとSSHの設定も消えてしまいます。この設定を永続化するため、Secretリソース化します。以下のコマンドでSecretリソースのマニフェストを生成してください。マニフェストの内容をコピーし、作業端末に``flux-ssh.yaml``などの名前でマニフェストを保存しておきましょう。マニフェストのサンプルは[こちら](./flux/flux-ssh.yaml)にもあります。
``` sh
kubectl create secret generic flux-ssh --from-file=/root/.ssh --dry-run -o yaml
```

ここまでできたらpod:fluxからログアウトします。また、この後fluxのマニフェストを修正するため、修正前にfluxを削除します。

``` sh
exit
kubectl delete -f flux.yaml
```

## Fluxマニフェストの修正・デプロイ

flux.yamlを修正し、先ほど作成したSSH設定をマウントする様にします。ポイントだけ以下の通り記載します。
``` yaml
kind: Deployment
metadata:
  name: flux
spec:
  template:
    spec:
      volumes:
      - name: ssh-config        # 追加         
        secret:                 # 追加 
          secretName: flux-ssh  # 追加 [FluxのSSH設定](#fluxのssh設定)の最後に作成したSecretリソース名を指定
          defaultMode: 0600     # 追加 defaultModeを0600にしないと使えないので注意
      containers:
      - name: flux
        volumeMounts:
        - name: ssh-config      # 追加 
          mountPath: /root/.ssh # 追加 
        args:
        - --git-url=gitlab:root/k8s.git # 修正 git@{ホスト名}を~/.ssh/configで設定したhostに修正
```

上記修正したら``flux-ssh.yaml``と``flux.yaml``をデプロイします。
``` sh
kubectl apply -f flux-ssh.yaml -f flux.yaml
```

デプロイ確認します。
``` sh
kubectl get pod
```

fluxの動作を確認するため、``k8s``レポ配下に以下のようなテスト用のマニフェストを作成します。
``` sh
cat <<EOF > flux-test.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: flux-test
  name: flux-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: flux-test
  template:
    metadata:
      labels:
        app: flux-test
    spec:
      containers:
      - image: nginx:1.19.2
        name: nginx
EOF
```

``k8s``レポの変更をGitLabにプッシュします。
``` sh
git add .
git commit -m "flux-test"
git push
```

デフォルトでは5分間隔でGitレポジトリと同期します。なのでしばらく待つと``flux-test``のpodが作成されるはずです。手動で同期したい場合は``fluxctl sync``コマンドを実行すればすぐに同期されます。なお、Fluxをdefault以外のnamespaceで動かしている場合は環境変数``FLUX_FORWARD_NAMESPACE``を設定しましょう。以下例ではdefaultですが一応設定してます。同期間隔などはfluxの設定で変えることもできます。詳しくはfluxのマニュアル[daemon(fluxd)](https://docs.fluxcd.io/en/latest/references/daemon/)を参照ください。
``` sh
export FLUX_FORWARD_NAMESPACE=default
fluxctl sync
```

``flux-test``のpodは不要なので削除しましょう。
``` sh
kubectl delete deployment flux-test
```

また、``k8s``レポにマニフェストが置いてあるとFluxにより自動デプロイされてしまうためマニフェストも削除してリモートレポジトリを更新しましょう。
``` sh
rm flux-test.yaml
git add .
git commit -m "delte flux-test"
git push
```

## イメージ更新時の自動デプロイ設定

Fluxはイメージレポジトリの変更を検知し、自動でマニフェストを更新することもできます。以下、fluxctlコマンドによりk8s上で動いているPod（Flux用語ではworkload）を確認します。Fluxをdefault以外のnamespaceで動かしている場合は環境変数``FLUX_FORWARD_NAMESPACE``を設定しましょう。以下例ではdefaultですが一応設定してます。また、default以外のnamepsaceで動いているPodを確認したい場合は``-n {namespace名}``をつけてください。
``` sh
export FLUX_FORWARD_NAMESPACE=default
fluxctl list-workloads
```
```
【出力例】
WORKLOAD                                        CONTAINER                    IMAGE                                                                  RELEASE  POLICY
default:deployment/flux                         flux                         docker.io/fluxcd/flux:1.20.0                                           ready
default:deployment/gitlab-runner-gitlab-runner  gitlab-runner-gitlab-runner  gitlab/gitlab-runner:alpine-v13.3.0                                    ready
                                                configure                    gitlab/gitlab-runner:alpine-v13.3.0
default:deployment/memcached                    memcached                    memcached:1.5.20                                                       ready
default:deployment/test-nginx                   test                         456247443832.dkr.ecr.ap-northeast-1.amazonaws.com/test:2020-0902-0554  ready
```

上記出力ではPOLICYがすべて空になっていると思います。POLICYに何も表示されないworkloadはイメージの自動更新がOFFになっています。以下コマンドでtestイメージを使って動いているtest-nginxの自動更新をONにします。その後、workloadを確認します。（fluxが持っていレポジトリの状態とリモートレポジトリの状態に差異があるとfluxctl automateに失敗する場合があります。その場合はfluxctl syncしてから再度fluxctl automateしてください。）
``` sh
fluxctl automate --workload=default:deployment/test-nginx
fluxctl list-workloads
```
```
【出力例】
WORKLOAD                                        CONTAINER                    IMAGE                                                                  RELEASE  POLICY
default:deployment/flux                         flux                         docker.io/fluxcd/flux:1.20.0                                           ready
default:deployment/gitlab-runner-gitlab-runner  gitlab-runner-gitlab-runner  gitlab/gitlab-runner:alpine-v13.3.0                                    ready
                                                configure                    gitlab/gitlab-runner:alpine-v13.3.0
default:deployment/memcached                    memcached                    memcached:1.5.20                                                       ready
default:deployment/test-nginx                   test                         456247443832.dkr.ecr.ap-northeast-1.amazonaws.com/test:2020-0902-0554  ready    automated
```

上記の様にPOLICYにautomatedがつくはずです。これでイメージレポジトリに最新のコンテナイメージが追加されると自動でK8sへデプロイされるはずです。

``test``レポジトリのディレクトリに移動し、index.htmlの内容を更新します。そして変更をリモートにプッシュします。
``` sh
cd ../test # パスは自身の環境にあわせてください
echo "cicd test v2" > index.html
git add .
git commit -m "v2"
git push
```

しばらくすればGitLab CICDでイメージがビルド&プッシュされ、イメージがプッシュされるとFluxが検知しマニフェストを書き換え、書き換えたマニフェストをFluxがデプロイし、test-nginxのPodのイメージが更新されます。長くても5分かからないと思います。GitLab CICDの状況はWEB UIで確認すると良いでしょう。Fluxの状態は以下のようなコマンドで見ることもできます。
``` sh
fluxctl list-images --workload=default:deployment/test-nginx
```
```
【出力例】
WORKLOAD                       CONTAINER  IMAGE                                                   CREATED
default:deployment/test-nginx  test       456247443832.dkr.ecr.ap-northeast-1.amazonaws.com/test
                                          '-> 2020-0903-0811                                      03 Sep 20 08:11 UTC
                                              2020-0902-0554                                      02 Sep 20 05:54 UTC
```

矢印で指しているイメージが現在のイメージを表しています。イメージがbuildした日付のものに切り替わったことを確認した後、ServiceのEXTERNAL-IPに表示されるELBのDNS名をコピーし、ブラウザなどで接続確認します。``cicd test v2``と表示されることを確認してください。

また、``k8s``レポジトリのディレクトリに移動し、``git pull``してみてください。Fluxが更新したマニフェストの状態を確認できます。

``` sh
cd ../k8s # パスは自身の環境にあわせてください
git pull
ll
```

# 5. OPA ポリシーチェック

## チェックポリシーの作成
k8sレポジトリ配下に``policy/dev``ディレクトリを作成し移動します。そして、コマンドで``resource.rego``ファイルを作成します。

``` sh
cat <<EOF > resource.rego
package main

workload_resources = [
  "Deployment",
  "DaemonSet",
  "StatefulSet",
]

# requestsが指定されていること
deny[msg] {
	input.kind = workload_resources[_]
	c := input.spec.template.spec.containers[_]
	not c.resources.requests

	msg = sprintf("%sコンテナにrequestsを指定してください", [c.name])
}

# limitsが指定されていること
deny[msg] {
	input.kind = workload_resources[_]
	c := input.spec.template.spec.containers[_]
	not c.resources.limits

	msg = sprintf("%sコンテナにlimitsを指定してください", [c.name])
}
EOF
```

上記、``resource.rego``はrego言語で記述されたポリシーです。簡単に内容を解説します。
- 以下に該当する場合拒否(deny)する
　　- kindがDeployment、DaemonSet、StatefulSetのいずれか
　　- ``spec.template.spec.containers.resources.requests``または``spec.template.spec.containers.resources.limits``が設定されていない

## マニフェストのCI
上記作成したresource.regoを使用したポリシーチェックをk8sマニフェストがレポジトリにpushされたタイミングで自動実行するようにします。``k8s``レポジトリに以下の``.gitlab-ci.yml``を作成します。

``` yaml
cat <<EOF > .gitlab-ci.yml
stages:
  - test

dev-test:
  image: instrumenta/conftest
  stage: test
  script:
    - conftest test -p policy/dev tset.yaml
  tags:
    - k8s
EOF
```

変更をコミットしてプッシュします。
``` sh
git add .
git commit -m "opa add"
git push
```

GitLabにWEBブラウザからログインします。k8sレポジトリのCICDパイプラインを確認します。おそらくパイプラインは失敗しているはずです。失敗の理由を確認するため[CI/CD]-[Pipelines]でstatusのfailedをクリック、失敗しているジョブをさらにクリックしてジョブの出力を確認します。以下のようにポリシーに反したマニフェストだったため失敗していることが確認できると思います。

```
 $ conftest test -p policy/ .
 FAIL - test.yaml - testコンテナにrequestsを指定してください
 FAIL - test.yaml - testコンテナにlimitsを指定してください
```

k8sレポジトリ以下にある``test.yaml``を以下の様に修正します。（変更箇所のみ抜粋）

``` yaml
---
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
      - image: 456247443832.dkr.ecr.ap-northeast-1.amazonaws.com/test:2020-0909-0728
        # ここからadd
        resources:
          limits:
            cpu: "250m"
            memory: "128Mi"
          requests:
            cpu: "250m"
            memory: "128Mi"
```

変更をコミットしてプッシュします。
``` sh
git add .
git commit -m "resources add"
git push
```

再度GitLabの画面でCICDパイプラインの状況を確認します。今度は成功しているはずです。このように、マニフェストを変更した時にチェックを行うことでマニフェストのテストを自動で行うことができます。また、``resource.rego``や``.gitlab-ci.yml``を拡張すれば他のポリシーやマニフェストに対してテストを行うこともできます。今回はmasterブランチに直接pushしてしまいましたが、たとえば``gitlab-flow``や``github-flow``などmasterではないブランチで変更し、その後masterへマージするブランチ戦略であれば、ポリシー違反したマニフェストをmasterに反映させない（つまり、実機に反映させない）という運用が可能です。

# 6. ステージング環境のセットアップ
ここまでの手順でDev環境のCICDセットアップは完了です。ステージングなど、他の環境に対してもデプロイを行いたい場合は以下の様にします。なおこの手順は開発環境とステージング環境が別々のK8sクラスタで構成している前提で記載しています。

## K8sレポジトリにStg用ブランチを作成
k8sレポジトリの``master``からStg用のブランチを作成してください。今回は``staging``として以降の手順をすすめます。

## Fluxのデプロイ
KUBECONFIGを変えるなどkubectlの向き先をステージング環境に切り替えた後、ステージング環境にFluxをデプロイしてください。その際、Dev環境で作成したマニフェスト``flux.yaml``および``flux-ssh.yaml``を流用してよいです。一点、flux podのargs指定している``--git-branch``を``staging``などブランチの指定を変えるのだけ忘れないでください。

これでk8sレポジトリの``staging``レポジトリに変更が発生すると、Fluxが自動でデプロイします。コンテナイメージの自動更新をしたい場合は``fluxctl automate``で自動更新を有効にしてください。なお、ステージングや本番などは安定版のコンテナを動かす環境かと思いますので、自動更新は行わずに手動アップデートが良いと思います。（自動は開発環境だけにする）fluxctlにより手動でイメージを更新するには``fluxctl release``コマンドを使用します。

## ステージング用のポリシー作成
ステージング環境に適用するマニフェストは開発環境よりも厳しいポリシーを設けます。たとえばliveness/readiness probeの設定を強制させたい場合は以下のポリシーになります。下記ファイルをmasterブランチで追加してください。

``` sh
cat <<EOF > probe.rego
package main

workload_resources = [
  "Deployment",
  "DaemonSet",
  "StatefulSet",
]

# livenessが指定されていること
deny[msg] {
	input.kind = workload_resources[_]
	c := input.spec.template.spec.containers[_]
	not c.livenessProbe

	msg = sprintf("%sコンテナにlivenessProbeを指定してください", [c.name])
}

# readinessが指定されていること
deny[msg] {
	input.kind = workload_resources[_]
	c := input.spec.template.spec.containers[_]
	not c.readinessProbe

	msg = sprintf("%sコンテナにreadinessProbeを指定してください", [c.name])
}
EOF
```

## ステージング用のCI追加
k8sレポジトリのルートにあるmasterブランチの``.gitlab-ci.yml``を以下の様に修正します。こうすることで、stg用のポリシーチェックはmasterブランチにマージされた場合のみ実行されます。k8sレポジトリはgitlab-flowを採用しているため、修正はfetureブランチ→masterブランチ→stagingブランチの順に行います。feture→masterへのマージは開発環境へのデプロイです。このときはdev-testをpassしたブランチをマージします。master→stagingへのマージはステージング環境へのデプロイです。この時はdev-testおよびstg-testをpassしたブランチとマージします。この流れは後ほどの手順でも触れます。

``` yaml
stages:
  - test

dev-test:
  image: instrumenta/conftest
  stage: test
  script:
    - conftest test -p policy/dev test.yaml
  tags:
    - k8s

stg-test:
  image: instrumenta/conftest
  stage: test
  script:
    - conftest test -p policy/stg test.yaml
  only:
    - master
    - staging
  tags:
    - k8s
```

``probe.rego``と``gitlab-ci.yaml``をリモートにpushしてください。
``` sh
git add .
git commit -m "stg policy add"
git push
```

gitlabのweb画面でパイプラインの状態を確認してください。おそらく、stg-testが失敗しているはずです。これはtest.yamlにprobeの設定をしていないためです。パイプラインが成功するようにtest.yamlを以下の様に修正してください。（修正箇所のみ抜粋）

``` yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
      - image: 456247443832.dkr.ecr.ap-northeast-1.amazonaws.com/test:2020-0909-0728
        # 以下、liveness/readinessを追加
        livenessProbe:
          httpGet:
            path: /
            port: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
```

修正したら変更をリモートにプッシュしてください。
``` sh
git add .
git commit -m "probe add"
git push
```

gitlabのweb画面でパイプラインの状態を確認してください。今度はパイプラインが成功しているはずです。パイプラインが成功したらmaster→stagingへマージします。

## ステージングへのデプロイ
ステージング環境へのデプロイはstagingブランチの変更をトリガにステージングへデプロイしたFluxが行います。stagingブランチの変更はmasuter→stagingへ変更をマージすることで行います。

gitlabのweb画面でk8sレポジトリを表示し[Merge Requests]-[New marge requet]を選択してください。source branchは``master``を選択し、target branchは``staging``を選択してください。選択したら[compare branch and continu]を選びます。マージリクエストの内容は自由に変更してください。[submit merge request]でマージリクエストを作成します。マージリクエストの画面で[merge]を選ぶとmaster→stagingへ変更が反映されます。

しばらく待つか``fluxctl sync``コマンドでリモートレポジトリとFluxを同期します。ステージング環境のtest-nginxを確認します。test.yamlに設定したprobeが追加されていることを確認してください。