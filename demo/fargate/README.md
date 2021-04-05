# Fargate上のコンテナで稼働するTomcatサンプルをTeamServerにオンボードさせてみる

## 前提条件
- この手順ではAWS CLIを使います。事前にインストールと設定を済ませてください。
- ecsTaskExecutionRoleという管理ポリシーが必要となります。ロールに存在しない場合は適宜作成してください。  
  参考） https://docs.aws.amazon.com/ja_jp/AmazonECS/latest/developerguide/task_execution_IAM_role.html
## 手順補足
- AWSの必要なものについてはすべてCLIで作成できるように手順やjsonファイルを用意していますが、適宜、コンソールから作成いただいても問題ありません。  
- タスク定義のjsonファイル内に[ACCOUNT_ID]となっている箇所がありますので、事前に自身のアカウントIDに置換しておいてください。

## 稼働確認用のDockerイメージ生成から、ECRへのpush

### 1. Contrastエージェント（Java）のDL
TeamServerからJava用のエージェントをダウンロードして、このREADME.mdと同じ位置に配置します。

### 2. 設定など変更（任意）
Contrastエージェントへのdocker-compose.yml内のenvironmentで指定できます。
設定可能な環境変数は以下のコマンドで確認できます。txtに出力するなどして、ご確認ください。
```bash
java -jar contrast.jar properties > properties.txt
```
その他、ポート番号など変更がある場合は適宜、修正してください。

### 3. Dockerビルド
docker-compose.ymlのある場所で  
```bash
docker-compose build
```  
ローカルでサンプルアプリの起動と、TeamServerへのオンボードを確認する場合は以下のコマンドを実行してください。
```bash
docker-compose up -d
```
`localhost:8080/sample`で接続します。またTeamServerでオンボードを確認してください。
### 4. ECRへのDockerイメージpush
```aws/ecr/readme.txt```の手順で、ECRリポジトリの作成から、上で生成したDockerイメージのpushまでを行います。

## ECSクラスターの作成から動作確認

### 1. AWS CLIの実行

以下の順番で各ディレクトリにあるreadme.txtにあるコマンドを実行していきます。

1. cloudwatch
2. vpc
3. subnet
4. igw
5. sg
6. ecs

### 2. TeamServerでのオンボード確認
編集中

以上

