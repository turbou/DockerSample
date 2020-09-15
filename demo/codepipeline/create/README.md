### PetClinicの脆弱性テストをCodePipelineでやってみる

#### 1. AWS CLIを実行するIAMユーザーに必要なポリシー

```iam_user_policy.json``` にCodePipelineを作成、実行するのに必要なポリシーが記載されています。

この内容で管理ポリシーを作るか、インラインポリシーとして、IAMユーザーにポリシーを割り当ててください。

#### 2. AWS CLIの実行

以下の順番で各ディレクトリにあるreadme.txtにあるコマンドを実行していきます。

1. s3
2. iam
3. cloudwatch
4. codebuild
5. codedeploy
6. codepipeline

#### 3. デプロイ先のEC2インスタンスへの事前準備

デプロイするEC2インスタンスに以下のAWS管理ポリシーを持つIAMロールを割り当ててください。

- AWSCodeDeployRole  
  後述するCodeDeployエージェントが稼働するために必要なポリシーです。
- AmazonS3ReadOnlyAccess  
  EC2からS3上のアーティファクト（リリース物）を取得するのに必要なポリシーです。

次にEC2インスタンスにCodeDeployエージェントをインストールしてください。
https://docs.aws.amazon.com/codedeploy/latest/userguide/codedeploy-agent-operations-install-linux.html  
上記のIAMロールでAWSCodeDeployRoleが割り当てられてないとエージェントのログにエラーが出続けます。

- エージェントログの場所  
  ```/var/log/aws/codedeploy-agent/codedeploy-agent.log```

#### 4. その他

- CodePipelineのソースのGithubのwebhook検知がうまく動かない場合は  
  https://docs.aws.amazon.com/ja_jp/codepipeline/latest/userguide/pipelines-webhooks-delete.html  
  を参考に余計なwebhookを削除してみる。



以上

