## Contrastエージェント付きのDockerコンテナをCroud Runにデプロイしてオンボード

### 前準備
- gcloud CLIをインストールしておいてください。  
- gcloud CLIの初期化まで済ませておいてください。

### デプロイ
- 組織の確認
  ```bash
  gcloud organizations list
  ```
- プロジェクトの作成または確認
  ```bash
  # プロジェクトを作成する場合
  gcloud projects create tabocom-nodejs-juiceshop --name="Juice Shop"
  # プロジェクト一覧の確認
  gcloud projects list
  # プロジェクトの詳細確認
  gcloud projects describe tabocom-nodejs-juiceshop
  # デフォルトプロジェクトの設定
  gcloud config set project tabocom-nodejs-juiceshop
  # 確認
  gcloud config list project
  ```
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
  # Dockerイメージのアップロード
  
  # push済みDockerイメージの一覧
  gcloud artifacts docker images list asia-northeast1-docker.pkg.dev/{YOUR_PROJECT}/docker-repo/hello-image
  ```
- デプロイ
  ```bash
  gcloud run deploy juice-shop --image=us-docker.pkg.dev/project/image --port=3000
  ```
  
