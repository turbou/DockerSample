AWS CLIの実行順序
1. s3
2. iam
3. cloudwatch
4. codebuild
5. codedeploy
6. codepipeline

デプロイするEC2インスタンスに以下のAWS管理ポリシーを持つIAMロールを割り当ててください。
・AmazonS3ReadOnlyAccess
・AWSCodeDeployRole

CodePipelineのソースのGithubのwebhook検知がうまく動かない場合は
https://docs.aws.amazon.com/ja_jp/codepipeline/latest/userguide/pipelines-webhooks-delete.html
を参考に余計なwebhookを削除してみる。

以上

