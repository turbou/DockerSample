## Contrastエージェント付きのDockerコンテナをCroud Runにデプロイしてオンボード

### 前準備
- gcloud アカウントの作成、課金設定、組織設定などは済ませておいてください。
- gcloud CLIをインストールと初期化まで済ませておいてください。  

### 使用するアプリケーション（Dockerイメージ）について
[Juice ShopのDockerサンプル](../../agent/nodejs/juice-shop) で、Juice ShopのDockerイメージをビルドしてください。  
```docker images```で以下のDockerイメージが存在する前提で手順を進めます。  
```
docker_juice-shop:1.0.0
```

### デプロイ
- 組織の確認
  ```bash
  gcloud organizations list
  ```
- プロジェクトの作成または確認
  ```bash
  # プロジェクトを作成する場合
  gcloud projects create tabocom-demo --name="Demo" --set-as-default

  # プロジェクト一覧の確認
  gcloud projects list

  # プロジェクトの詳細確認
  gcloud projects describe tabocom-demo
  
  # 作業プロジェクトを設定
  gcloud config set project tabocom-demo
  
  # 確認
  gcloud config list project
  ```
- プロジェクトへの課金の有効化  
  プロジェクトに請求先アカウントをリンクする必要があります。  
  下記のドキュメントを参考にプロジェクトへの課金の有効化を行ってください。  
  https://cloud.google.com/billing/docs/how-to/modify-project?hl=ja  

- プロジェクトへのAPIの有効化
  ```bash
  gcloud services enable artifactregistry.googleapis.com
  gcloud services enable run.googleapis.com
  ```
  APIの有効化でエラーがでる場合は、ロールの割り当てを適切に設定し直してください。

- アーティファクト（新しいタイプのDockerイメージレジストリのこと）
  ```bash
  # リポジトリの一覧
  gcloud artifacts repositories list
  
  # リポジトリの作成
  gcloud artifacts repositories create my-repo --repository-format=docker --location=asia-northeast1
  
  # リポジトリの一覧（再）
  gcloud artifacts repositories list
  
  # Artifact Registry認証情報付与
  gcloud auth configure-docker asia-northeast1-docker.pkg.dev
  
  # Dockerイメージのタグ付け
  docker tag docker_juice-shop:1.0.0 asia-northeast1-docker.pkg.dev/tabocom-demo/my-repo/docker_juice-shop:1.0.0
  
  # Dockerイメージのアップロード
  docker push asia-northeast1-docker.pkg.dev/tabocom-demo/my-repo/docker_juice-shop:1.0.0
  
  # push済みDockerイメージの一覧
  gcloud artifacts docker images list asia-northeast1-docker.pkg.dev/tabocom-demo/my-repo
  ```
- デプロイ
  ```bash
  gcloud run deploy juice-shop --image=asia-northeast1-docker.pkg.dev/tabocom-demo/my-repo/docker_juice-shop:1.0.0 --port=3000 --region=asia-northeast1 --allow-unauthenticated --memory=2048Mi --min-instances=0 --max-instances=1
  ```
  数分ほどでデプロイが完了して、それからさらに2, 3分でJuice Shopを閲覧することができます。  
  URLは上記CLIコマンドの応答でも確認できますし、コンソールのCroud Runでも確認することができます。

**後片付けについては追記予定**

以上

