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

#### kubectlにSecretを登録する。
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
