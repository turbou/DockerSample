# Django, uWSGI, nginxをDocker, k8s, EKSで動かしてみる

## 事前準備
### ダミーのcontrast_security.yamlを本物と入れ替え
python版のcontrast_security.yamlをダウンロードしてください。
```
src/contrast_security.yaml
```

## まずはDockerで起動、オンボードしてみる
### Dockerビルド
1. Dockerビルド
    ```bash
    docker-compose build --no-cache
    ```

### コンテナ起動
1. コンテナ起動
    ```bash
    docker-compose up -d
    ```
2. DBマイグレート
    ```bash
    docker-compose exec django ./manage.py makemigrations
    docker-compose exec django ./manage.py migrate
    ```
4. 管理ユーザーの作成
    ```bash
    docker-compose exec django ./manage.py createsuperuser
    ```
    ユーザ名、メールアドレス、パスワードは適当に設定してください。
5. 静的コンテンツの格納
    ```bash
    docker-compose exec django ./manage.py collectstatic
    ```
    static/ディレクトリに静的コンテンツがコピーされます。
6. Djangoアプリ接続確認
  http://localhost:8000 で確認（管理サイトは http://localhost:8000/admin ）
7. Contrastサーバでオンボード確認

## DockerDesktopのk8sで起動、オンボードしてみる
### k8sのファイル生成について
既にk8sフォルダにyamlファイルがありますが、komposeを使ったコマンドを記しておきます。
1. kompose
    ```bash
    # docker-compose.ymlのある場所で
    kompose convert --volumes hostPath -o k8s
    ```
### デプロイ
1. apply
    ```bash
    kubectl apply -f k8s/
    ```
2. 確認
    ```bash
    kubectl get pods
    ```
3. ポートフォワード
    ```bash
    kubectl get svc
    ```
    ```
    NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
    django       ClusterIP   10.107.23.39     <none>        8001/TCP   6m53s
    kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP    96m
    nginx        ClusterIP   10.103.222.187   <none>        8000/TCP   6m53s
    ```
    ```bash
    kubectl port-forward svc/nginx 8001:8000
    ```
4. Djangoアプリ接続確認
  http://localhost:8001 で確認（管理サイトは http://localhost:8001/admin ）
5. Contrastサーバでオンボード確認

## EKSで動かしてみる.
### DockerイメージをECRにpush
リポジトリはdjango_uwsgiという名前で作成済みとします。
1. docker login  
    profileの指定に注意してください。
    ```bash
    aws ecr get-login-password --region ap-northeast-1 --profile contrastsecurity | docker login --username AWS --password-stdin XXXXXXXXXXXX.dkr.ecr.ap-    northeast-1.amazonaws.com
    ```
2. タグ付け
    ```bash
    docker tag django_uwsgi:1.0.0 XXXXXXXXXXXX.dkr.ecr.ap-northeast-1.amazonaws.com/django_uwsgi:1.0.0
    ```
3. docker push
    ```bash
    docker push XXXXXXXXXXXX.dkr.ecr.ap-northeast-1.amazonaws.com/django_uwsgi:1.0.0
    ```

以上