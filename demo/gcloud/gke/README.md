# GKE上のアプリをContrastサーバにオンボード
Contrastエージェント付きのDockerコンテナをCloud Runにデプロイして、Contrastサーバにオンボードするまでの手順です。

## 事前準備
Google Cloud用デモ共通[事前準備](../README.md#事前準備)を参照してください。

## 構成
今回使用するgcloudの構成は以下のような感じです。
  ```
  組織
   └─ プロジェクト
      ├─ アーティファクト
      └─ サービス
  ```

## 実際の手順
### 組織
組織については事前準備で既に作成済みだと思うので、ここでは確認のみです。
- 組織の確認
  ```bash
  gcloud organizations list
  ```
### プロジェクト
- プロジェクトの作成
  ```bash
  # プロジェクトを作成する場合
  gcloud projects create tabocom-demo --name="Demo" --set-as-default
  ```
- 作成したプロジェクトの確認
  ```bash
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
  # 確認
  gcloud services list --enabled
  ```
  APIの有効化でエラーがでる場合は、ロールの割り当てを適切に設定し直してください。

### アーティファクト
アーティファクトはいろんなタイプのバイナリを保管できるもので、その一部でコンテナレジストリの機能が提供されています。
- アーティファクト
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
  gcloud artifacts docker images list --include-tags asia-northeast1-docker.pkg.dev/tabocom-demo/my-repo
  ```

### クラスター
- クラスタの作成
  ```bash
  # 確認
  gcloud container clusters list --location=asia-northeast1
  # 作成
  gcloud container clusters create-auto juice-shop-cluster --location=asia-northeast1
  ```
- 認証プラグインをインストール
  ```bash
  gcloud components install gke-gcloud-auth-plugin
  # バージョンを確認
  gke-gcloud-auth-plugin --version
  ```
- クラスタの認証情報を取得
  ```bash
  gcloud container clusters get-credentials juice-shop-cluster --location=asia-northeast1
  ```
- デプロイ
  ```bash
  kubectl create deployment juice-shop-server --image=asia-northeast1-docker.pkg.dev/tabocom-demo/my-repo/docker_juice-shop:1.0.0
  ```
- アプリケーションの公開
  ```bash
  kubectl expose deployment juice-shop-server --type LoadBalancer --port 80 --target-port 3000
  ```
- アプリケーションに接続
  ```bash
  kubectl get service juice-shop-server
  NAME                TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)        AGE
  juice-shop-server   LoadBalancer   34.118.232.132   34.146.126.238   80:32545/TCP   60s
  ```
  この場合だと、http://34.146.126.238 でJuiceShopを開けます。

## 後片付け
### サービス
- デプロイしたサービスの削除
  ```bash
  # サービスの削除
  gcloud run services delete juice-shop --region=asia-northeast1
  # サービス一覧の確認
  gcloud run services list
  ```

以上

