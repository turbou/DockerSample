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
1. 作業プロファイルを指定（任意）
    ```bash
    export AWS_PROFILE=contrastsecurity
    ```
1. リポジトリ作成
    ```bash
    # nginx
    aws ecr create-repository --repository-name django_uwsgi_nginx --region ap-northeast-1
    # django
    aws ecr create-repository --repository-name django_uwsgi_django --region ap-northeast-1
    ```
2. docker login  
    ```bash
    aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin XXXXXXXXXXXX.dkr.ecr.ap-northeast-1.amazonaws.com
    ```
3. タグ付け
    ```bash
    # django
    docker tag django_uwsgi_nginx:1.0.0 XXXXXXXXXXXX.dkr.ecr.ap-northeast-1.amazonaws.com/django_uwsgi_nginx:1.0.0
    # django
    docker tag django_uwsgi_django:1.0.0 XXXXXXXXXXXX.dkr.ecr.ap-northeast-1.amazonaws.com/django_uwsgi_django:1.0.0
    ```
4. docker push
    ```bash
    # push
    docker push XXXXXXXXXXXX.dkr.ecr.ap-northeast-1.amazonaws.com/django_uwsgi_nginx:1.0.0
    docker push XXXXXXXXXXXX.dkr.ecr.ap-northeast-1.amazonaws.com/django_uwsgi_django:1.0.0
    # 確認
    aws ecr list-images --repository-name django_uwsgi_nginx
    aws ecr list-images --repository-name django_uwsgi_django
    ```

### デプロイのための準備
作業するPCにeksctlがインストールされていること
1. VPC、サブネットの作成
    作成中
2. ロールの作成
    作成中
3. クラスタの作成
    ```bash
    aws eks create-cluster --region ap-northeast-1 \
        --name django-uwsgi-demo-cluster \
        --kubernetes-version 1.25 \
        --role-arn arn:aws:iam::771960604435:role/djangoUwsgiEKSClusterRole \
        --resources-vpc-config \
        subnetIds=subnet-03a0f83c73fb09cef,subnet-02e6085aee74f166b
    ```
4. ノードグループの作成
    ```bash
    aws eks create-nodegroup \
        --cluster-name django-uwsgi-demo-cluster \
        --nodegroup-name django-uwsgi-nodegroup \
        --scaling-config minSize=1,maxSize=1,desiredSize=1 \
        --disk-size 20 \
        --subnets subnet-03a0f83c73fb09cef subnet-02e6085aee74f166b \
        --instance-types t3.medium \
        --ami-type AL2_x86_64 \
        --remote-access ec2SshKey=Taka \
        --node-role arn:aws:iam::771960604435:role/djangoUwsgiEKSNodeRole 
    ```

### デプロイ
1. ローカルとEKSの接続
    ```bash
    aws eks update-kubeconfig --region ap-northeast-1 --name django-uwsgi-demo-cluster
    ```
2. ネープスペースの作成
    ```bash
    kubectl create namespace django-uwsgi
    kubens django-uwsgi
    ```
3. デプロイ
    ```bash
    kubectl apply -f ./k8s -n django-uwsgi
    ```

### 後片付け
1. デプロイメントの削除
    ```bash
    kubectl delete -f ./k8s -n django-uwsgi
    ```
2. ネームスペースの削除
    ```bash
    kubectl delete namespace django-uwsgi
    ```
3. ノードグループの削除
    ```bash
    aws eks list-nodegroups --cluster-name django-uwsgi-demo-cluster --region ap-northeast-1
    aws eks delete-nodegroup \
        --nodegroup-name django-uwsgi-nodegroup \
        --cluster-name django-uwsgi-demo-cluster |
        --region ap-northeast-1
    ```
4. クラスタの削除
    ```bash
    aws eks delete-cluster --name django-uwsgi-demo-cluster --region ap-northeast-1
    ```
5. kubeconfigの削除
    ```bash
    kubectl config unset contexts.arn:aws:eks:ap-northeast-1:XXXXXXXXXXXX:cluster/django-uwsgi-demo-cluster
    kubectl config unset clusters.arn:aws:eks:ap-northeast-1:XXXXXXXXXXXX:cluster/django-uwsgi-demo-cluster
    kubectl config unset users.arn:aws:eks:ap-northeast-1:XXXXXXXXXXXX:cluster/django-uwsgi-demo-cluster
    ```

以上
