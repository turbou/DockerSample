# Fargate上のコンテナで稼働するTomcatサンプルをTeamServerにオンボードさせてみる

## 稼働確認用のDockerイメージを生成する

#### 1. Contrastエージェント（Java）のDL
    TeamServerからJava用のエージェントをダウンロードして、このREADME.mdと同じ位置に配置します。

#### 2. 設定など変更（任意）
    Contrastエージェントへのdocker-compose.yml内のenvironmentで指定できます。
    設定可能な環境変数は以下のコマンドで確認できます。txtに出力するなどして、ご確認ください。
    ```
    java -jar contrast.jar properties > properties.txt
    ```
    その他、ポート番号など変更がある場合は適宜、修正してください。

#### 3. Dockerビルド
    docker-compose.ymlのある場所で  
    ```
    docker-compose build
    ```  

#### 3. サンプルアプリの中の簡単な説明
- buildspec.yml  
  CodeBuildのビルドアクションで使用されるbuildspecファイルです。
- testspec.yml  
  CodeBuildのテストアクションで使用されるbuildspecファイルです。  
  内部で curlによってSQLInjectionが発生するリクエストを発行し、check_vul.shで、  
  TeamServerより脆弱性(Critical指定)のカウントを取得しています。
- appspec.yml  
  CodeDeployで使用されるappspecファイルです。

## AWS CodePipelineの構築

#### 1. AWS CLIを実行するIAMユーザーに必要なポリシー

```iam_user_policy.json``` にCodePipelineを作成、実行するのに必要なポリシーが記載されています。

この内容で管理ポリシーを作るか、インラインポリシーとして、IAMユーザーにポリシーを割り当ててください。

#### 2. デプロイ先のEC2インスタンスへの事前準備

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

#### 3. AWS CLIの実行

以下の順番で各ディレクトリにあるreadme.txtにあるコマンドを実行していきます。

1. s3
2. iam
3. cloudwatch
4. codebuild
5. codedeploy
6. codepipeline

CodePipelineの作成が成功すると、すぐにCodePipelineが動き出します。  
それ以降は、フォークしたPetClinicDemoへのpushを契機にCodePipelineが動きます。

#### 4. その他

- CodePipelineのソースのGithubのwebhook検知がうまく動かない場合は  
  https://docs.aws.amazon.com/ja_jp/codepipeline/latest/userguide/pipelines-webhooks-delete.html  
  を参考に余計なwebhookを削除してみる。

## 脆弱性検知のテストについて
サンプルのPetClinicDemoにはSQLInjectionの脆弱性を仕込んであります。  
```
./src/main/java/org/springframework/samples/petclinic/owner/OwnerRepositoryCustomImpl.java
```
の中の *unsafe*, *safe* のコードを切り替えることで、脆弱性検知によるビルド失敗または脆弱性検知なしによるビルド成功からのデプロイまでの  
CodePipelineの動きを切り替えることができます。
```java
public Collection<Owner> findByLastName(String lastName) {
    System.out.println("Vulnerable method 1");
    // unsafe -- 検索機能を開発
    String sqlQuery = "SELECT DISTINCT owner FROM Owner owner left join fetch owner.pets WHERE owner.lastName LIKE '" + lastName + "%'"; 
    TypedQuery<Owner> query = this.entityManager.createQuery(sqlQuery, Owner.class);
    // unsafe -- end

    // safe -- start
    //String sqlQuery = "SELECT DISTINCT owner FROM Owner owner left join fetch owner.pets WHERE owner.lastName LIKE :lastName";
    //TypedQuery<Owner> query = this.entityManager.createQuery(sqlQuery, Owner.class);
    //query.setParameter("lastName", lastName + "%");
    // safe -- end
    return query.getResultList();
}
```

以上

