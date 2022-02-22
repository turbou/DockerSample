# PersistentVolumeが作成されない場合の回避手順

## 前準備
### 各ファイルの設定を一部修正
#### PodのDB接続先のIPアドレスを修正
```k8s-simple.yml``` 内の**CONTRAST_JDBC_URL**のIPアドレスをホストOSのIPアドレスに合わせて修正します。

#### Persistent Volumeのhostpathを自身の環境に合わせて修正します。
```pv-data.yml```, ```pv-agents.yml```の*spec.hostPath.path*を権限のあるディレクトリパスに変更します。
```yaml
  hostPath:
    path: /Users/turbou/Documents/git/ContrastSecurity/demo/teamserver_k8s/k8s/data # ここです。
    type: DirectoryOrCreate
```
#### PersistentVolumeとPersistentVolumeClaimを手動で作成する。
```bash
# PersistentVolumeの作成
kubectl apply -f pv-data.yml
kubectl apply -f pv-agents.yml
# PersistentVolumeClaimの作成
kubectl apply -f pvc-data.yml
kubectl apply -f pvc-agents.yml
# 確認
kubectl get pvc,pv
```

## サービスの起動
### サービスの起動
VolumeClaimTemplateの定義のないymlを実行します。
```bash
kubectl apply -f k8s-simple_without_pv.yml
```
### Podの状態確認いろいろ
```bash
# Podのステータス確認
kubectl get pods
# Podの詳細確認
kubectl describe pods contrast-0
# Podのログを確認 (コンテナIDはinit-migrations、init-agents、contrastとかです。describeの結果で確認できます)
# エラーが起きた場合はこのログで該当する処理のコンテナIDを指定して、エラー内容を確認してください。
kubectl logs -f --timestamps=true contrast-0 -c <コンテナID>
```
**もしも、PodがPendingのままだった場合は、docker desktopの設定のリソースのメモリを大きくしてみてください。**  
以下のようになったらOKです。6分かからないぐらいです。
```bash
NAME         READY   STATUS    RESTARTS        AGE
contrast-0   1/1     Running   2 (5m16s ago)   9m22s
```
### ローカルPCからアクセスできるようにポートフォワードさせる。
```bash
# 一応、ポートとか確認する場合
kubectl describe services contrast
# ポートフォワード (ポートフォワードしている間、接続可能です)
kubectl port-forward service/contrast 28000:28000
```
## 接続してみる。
SuperAdminアカウントと例のパスワードでログインしてみてください。
```
http://localhost:28000/Contrast
```
## 後片付け
1. ポートフォワードをCtrl+Cで停止します。
2. サービスを停止します。
    ```bash
    kubectl delete -f k8s-simple_without_pv.yml 
    ```
3. kubectlのSecretとConfigMapを削除します。 (残していても問題ないです)
    ```bash
    kubectl get secrets
    kubectl delete secret contrast-database contrast-license
    kubectl get configmap
    kubectl delete configmaps contrast-config
    ```
4. pvc, pvの削除
    ```bash
    kubectl get pvc,pv
    kubectl delete pvc agents-pvc data-pvc
    kubectl delete pv agents-pv data-pv
    ```    
6. MySQLコンテナの停止
    ```bash
    cd mysql/
    docker-compose down
    # 必要に応じて
    rm -fr ./data
    ```
  
以上
