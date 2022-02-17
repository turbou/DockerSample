## Contrast TeamServerのコンテナをk8sで動かしてみる

### 動作確認済み環境
macOS 12.2
docker desktop 4.5.0 (Kubernetes v1.22.5)

### 前準備
#### Contrastのライセンスファイルを取得
すでにあるダミーライセンスファイルのcontrast-12-31-2022.licと入れ替えます。

#### Kubernetesを有効化
docker desktopの設定画面でKubernetesを有効化してください。  
Show system containersはオフのままでも動きました。

#### MySQLコンテナを稼働させます。
```bash
cd mysql/
docker-compose up -d
docker-compose ps
```

#### PodのDB接続先のIPアドレスを修正する。
```k8s-simple.yml``` 内の**CONTRAST_JDBC_URL**のIPアドレスをホストのIPアドレスに合わせて修正します。

#### kubectlにSecretとConfigMapを登録する。
このREADME.mdの配置されているディレクトリに戻ります。  
```bash
# とりあえず今のSecretsを確認
kubectl get secrets
# DBパスワードを登録このパスワードはmysql/docker-compose.yml内と合わせます。
kubectl create secret generic contrast-database --from-literal=password="password"
kubectl create secret generic contrast-license --from-file=license=contrast-12-31-2022.lic
# 登録後のSecretsを確認
kubectl get secrets
```

```bash
# とりあえず今のConfigMapを確認
kubectl get configmaps
kubectl create configmap contrast-config --from-file=./contrast.properties
# 登録された中身を確認
kubectl describe configmaps contrast-config
```

### サービスの起動
#### サービスの起動
```bash
kubectl apply -f k8s-simple.yml
```
#### Podの状態確認いろいろ
```bash
# Podのステータス確認
kubectl get pods
# Podの詳細確認
kubectl describe pods contrast-0
# Podのログを確認 (コンテナIDはinit-migrations、init-agents、contrastとかです。describeの結果で確認できます)
# エラーが起きた場合はこのログで該当する処理のコンテナIDを指定して、エラー内容を確認してください。
kubectl logs -f --timestamps=true contrast-0 -c <コンテナID>
```
以下のようになったらOKです。10分かからないぐらいです。
```bash
NAME         READY   STATUS    RESTARTS        AGE
contrast-0   1/1     Running   2 (5m16s ago)   9m22s
```
#### ローカルPCからアクセスできるようにポートフォワードさせる。
```bash
# 一応、ポートとか確認する場合
kubectl describe services contrast
# ポートフォワード (ポートフォワードしている間、接続可能です)
kubectl port-forward service/contrast 28000:28000
```
#### 接続してみる。
SuperAdminアカウントと例のパスワードでログインしてみてください。
```
http://localhost:28000/Contrast
```
### 後片付け
1. ポートフォワードをCtrl+Cで停止します。
2. サービスを停止します。
    ```bash
    kubectl delete -f k8s-simple.yml 
    ```
3. kubectlのSecretとConfigMapを削除します。 (残していても問題ないです)
    ```bash
    kubectl get secrets
    kubectl delete secret contrast-database
    kubectl delete secret contrast-license
    kubectl get kubectl get configmap
    kubectl delete configmaps contrast-config
    ```
4. MySQLコンテナの停止
    ```bash
    cd mysql/
    docker-compose down
    ```
  
以上
