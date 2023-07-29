# Google Cloudのデモ用ガイド
- Croud Run
- GKE

## 事前準備
### Google Cloudを使うための前準備
- gcloud アカウントの作成、課金設定、組織設定などは済ませておいてください。
- gcloud CLIをインストールと初期化まで済ませておいてください。  

### 使用するアプリケーション（Dockerイメージ）の準備について
**ContrastのNodeJSエージェントが含まれているDockerイメージ**を使ってデプロイします。  
[Juice ShopのDockerサンプル](../../agent/nodejs/juice-shop) で、Juice ShopのDockerイメージをビルドしてください。  
```docker images```で以下のDockerイメージが存在する前提で手順を進めます。  
```
docker_juice-shop:1.0.0
```
