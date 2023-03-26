# Django, uWSGI, nginxをDocker, k8s, EKSで動かしてみる

## 事前準備
### ダミーのcontrast_security.yamlを本物と入れ替え
python版のcontrast_security.yamlをダウンロードしてください。
```
django/contrast_security.yaml
```
内容のサンプルとしては下のとおりです。
```yaml
api: 
  url: https://eval.contrastsecurity.com/Contrast
  api_key: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  service_key: YYYYYYYYYYYYYYYY
  user_name: agent_ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ
agent: 
  service: 
    host: 127.0.0.1
    port: 30555
server:
  environment: development
  name: Django-uWSGI_k8s_Container
application:
  name: Django-uWSGI_k8s
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
2. 管理ユーザーの作成
    ```bash
    docker-compose exec django ./manage.py createsuperuser
    ```
    ユーザ名、メールアドレス、パスワードは適当に設定してください。
3. 静的コンテンツの格納
    ```bash
    docker-compose exec django ./manage.py collectstatic
    ```
    static/ディレクトリに静的コンテンツがコピーされます。このディレクトリはnginxコンテナにもマウントされているため  
    Djangoの管理サイトを表示する際に静的コンテンツが表示されるようになります。
4. Djangoアプリ接続確認
  http://localhost:8000 で確認（管理サイトは http://localhost:8000/admin ）
5. Contrastサーバでオンボード確認

### 後片付け
1. コンテナ停止
    ```bash
    docker-compose down
    ```

## MacのDockerDesktopのk8sで起動、オンボードしてみる
### k8sのファイル生成について
既にk8sフォルダにyamlファイルがありますが、volumesのpathが実際の環境と異なるためkomposeコマンドを使って再作成してください。
1. kompose
    ```bash
    # docker-compose.ymlのある場所で
    kompose convert --volumes hostPath -o k8s
    # 余計なファイルが出来るので削除してください。そのままだと余計なサービスが起動されます。
    rm -f k8s/nginx-tcp-service.yaml
    ```
### デプロイ
1. apply
    ```bash
    kubectl apply -f k8s/
    ```
2. 確認
    ```bash
    kubectl get pods
    kubectl get svc
    ```
3. 管理ユーザーの作成
    ```bash
    kubectl exec -it [POD名] -- ./manage.py createsuperuser
    ```
    ユーザ名、メールアドレス、パスワードは適当に設定してください。
4. 静的コンテンツの格納
    ```bash
    kubectl exec -it [POD名] -- ./manage.py collectstatic
    ```
    static/ディレクトリに静的コンテンツがコピーされます。このディレクトリはnginxコンテナにもマウントされているため  
    Djangoの管理サイトを表示する際に静的コンテンツが表示されるようになります。
5. Djangoアプリ接続確認
  http://localhost:8000 で確認（管理サイトは http://localhost:8000/admin ）
6. Contrastサーバでオンボード確認

### 後片付け
1. デプロイメントの削除
    ```bash
    kubectl delete -f k8s/
    ```

## EKSで動かしてみる.
**EKS、ECRなどを操作する権限を既に持っている前提となります。**  
### 使用するプロファイルの設定
1. 作業プロファイルを指定（任意です。お使いになるプロファイルに合わせてください）
    ```bash
    export AWS_PROFILE=contrastsecurity
    ```
### DockerイメージをECRにpush
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
5. デプロイメントyamlの修正  
    ```k8s/django-deployment.yaml```, ```k8s/nginx-deployment.yaml``` それぞれのimageの値もECRのURIに変更してください。

### デプロイのための準備
作業するPCにeksctlがインストールされていること
1. VPC、サブネットの作成  
    ```bash
    # VPC
    aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications ResourceType=vpc,Tags=[{"Key=Name,Value=django-uwsgi-vpc"}]

    # Check VPC ID
    aws ec2 describe-vpcs --filters "Name=tag:Name,Values=django-uwsgi-vpc" --query 'Vpcs[*].[VpcId,CidrBlock]' --output table

    # Create Subnet(Public1)
    aws ec2 create-subnet \
        --vpc-id [VPC_ID] \
        --cidr-block 10.0.0.0/20 \
        --availability-zone ap-northeast-1a \
        --tag-specifications ResourceType=subnet,Tags=[{"Key=Name,Value=django-uwsgi-subnet-public1"}]

    # Create Subnet(Public2)
    aws ec2 create-subnet \
        --vpc-id [VPC_ID] \
        --cidr-block 10.0.16.0/20 \
        --availability-zone ap-northeast-1c \
        --tag-specifications ResourceType=subnet,Tags=[{"Key=Name,Value=django-uwsgi-subnet-public2"}]

    # Create Subnet(Private1)
    aws ec2 create-subnet \
        --vpc-id [VPC_ID] \
        --cidr-block 10.0.128.0/20 \
        --availability-zone ap-northeast-1a \
        --tag-specifications ResourceType=subnet,Tags=[{"Key=Name,Value=django-uwsgi-subnet-private1"}]
    
    # Create Subnet(Private2)
    aws ec2 create-subnet \
        --vpc-id [VPC_ID] \
        --cidr-block 10.0.144.0/20 \
        --availability-zone ap-northeast-1c \
        --tag-specifications ResourceType=subnet,Tags=[{"Key=Name,Value=django-uwsgi-subnet-private2"}]
    
    # Create IGW
    aws ec2 create-internet-gateway --tag-specifications ResourceType=internet-gateway,Tags=[{"Key=Name,Value=django-uwsgi-igw"}]
    
    # Check VPC ID
    aws ec2 describe-vpcs --filters "Name=tag:Name,Values=django-uwsgi-vpc" --query 'Vpcs[*].[VpcId,CidrBlock]' --output table

    # Attach IGW to VPC
    aws ec2 attach-internet-gateway --vpc-id [VPC_ID] --internet-gateway-id [IGW_ID]

    # Create Custom RootTable
    aws ec2 create-route-table --vpc-id [VPC_ID] ResourceType=route-table,Tags=[{"Key=Name,Value=django-uwsgi-rtb-public"}]

    aws ec2 create-route --route-table-id [RTB_ID] --destination-cidr-block 0.0.0.0/0 --gateway-id [IGW_ID]

    # Check Subnet ID
    aws ec2 describe-subnets --filters "Name=tag:Name,Values=django-uwsgi-subnet-public1" --query 'Subnets[*].[VpcId,SubnetId]' --output table
    aws ec2 describe-subnets --filters "Name=tag:Name,Values=django-uwsgi-subnet-public2" --query 'Subnets[*].[VpcId,SubnetId]' --output table

    # Associate RootTable
    aws ec2 associate-route-table  --subnet-id [SUBNET1_ID] --route-table-id [RTB_ID]
    aws ec2 associate-route-table  --subnet-id [SUBNET2_ID] --route-table-id [RTB_ID]
    
    # SecurityGroup
    # Check VPC ID
    aws ec2 describe-vpcs --filters "Name=tag:Name,Values=django-uwsgi-vpc" --query 'Vpcs[*].[VpcId,CidrBlock]' --output table

    # Create SecurityGroup
    aws ec2 create-security-group \
        --group-name django-uwsgi-sg \
        --description "Django uWSGI Demo" \
        --vpc-id [VPC_ID] \
        --tag-specifications \
        ResourceType=security-group,Tags=[{"Key=Name,Value=django-uwsgi-sg"}] 
    # Add Inbound Rule
    aws ec2 authorize-security-group-ingress --group-id [SG_ID] --protocol tcp --port 8000 --cidr 0.0.0.0/0
    ```
2. ロールの作成  
    ```bash
    # CreateRole(EKS Cluster)
    aws iam create-role --path "/service-role/" --role-name djangoUwsgiEKSClusterRole --assume-role-policy-document file://awscli/role_eks-cluster.json
    # Attach Policy
    aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEKSClusterPolicy --role-name djangoUwsgiEKSClusterRole

    # CreateRole(EKS NodeGroup)
    aws iam create-role --path "/service-role/" --role-name djangoUwsgiEKSNodeRole --assume-role-policy-document file://awscli/role_eks-node.json
    # Attach Policy
    aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEKSWorkerNodePolicy --role-name djangoUwsgiEKSNodeRole
    aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerRegistryReadOnly --role-name djangoUwsgiEKSNodeRole
    aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEKS_CNI_Policy --role-name djangoUwsgiEKSNodeRole
    ```
3. クラスタの作成  
    ```bash
    # Check Subnet ID
    aws ec2 describe-subnets --filters "Name=tag:Name,Values=django-uwsgi-subnet-public1" --query 'Subnets[*].[VpcId,SubnetId]' --output table
    aws ec2 describe-subnets --filters "Name=tag:Name,Values=django-uwsgi-subnet-public2" --query 'Subnets[*].[VpcId,SubnetId]' --output table
    # Create Cluster
    aws eks create-cluster --region ap-northeast-1 \
        --name django-uwsgi-demo-cluster \
        --kubernetes-version 1.25 \
        --role-arn arn:aws:iam::XXXXXXXXXXXX:role/djangoUwsgiEKSClusterRole \
        --resources-vpc-config \
        subnetIds=[SUBNET1_ID],[SUBNET2_ID]
    ```
4. ノードグループの作成  
    ```bash
    # Check Subnet ID
    aws ec2 describe-subnets --filters "Name=tag:Name,Values=django-uwsgi-subnet-public1" --query 'Subnets[*].[VpcId,SubnetId]' --output table
    aws ec2 describe-subnets --filters "Name=tag:Name,Values=django-uwsgi-subnet-public2" --query 'Subnets[*].[VpcId,SubnetId]' --output table
    # Create NodeGroup
    aws eks create-nodegroup \
        --cluster-name django-uwsgi-demo-cluster \
        --nodegroup-name django-uwsgi-nodegroup \
        --scaling-config minSize=1,maxSize=1,desiredSize=1 \
        --disk-size 20 \
        --subnets [SUBNET1_ID] [SUBNET2_ID] \
        --instance-types t3.medium \
        --ami-type AL2_x86_64 \
        --remote-access ec2SshKey=Taka \
        --node-role arn:aws:iam::XXXXXXXXXXXX:role/djangoUwsgiEKSNodeRole
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
        --cluster-name django-uwsgi-demo-cluster \
        --region ap-northeast-1
    ```
4. クラスタの削除  
    **ノードグループの削除にしばらく時間がかかるので10分ぐらいしてからやってみてください。**
    ```bash
    aws eks delete-cluster \
        --name django-uwsgi-demo-cluster \
        --region ap-northeast-1
    ```
5. kubeconfigの削除
    ```bash
    # 確認
    kubectl config view
    # カレントコンテキストを元に戻す
    kubectl config use-context docker-desktop
    # それぞれ削除
    kubectl config unset contexts.arn:aws:eks:ap-northeast-1:XXXXXXXXXXXX:cluster/django-uwsgi-demo-cluster
    kubectl config unset clusters.arn:aws:eks:ap-northeast-1:XXXXXXXXXXXX:cluster/django-uwsgi-demo-cluster
    kubectl config unset users.arn:aws:eks:ap-northeast-1:XXXXXXXXXXXX:cluster/django-uwsgi-demo-cluster
    ```
6. AWSのその他のリソース
    ```bash
    # ECR
    aws ecr delete-repository --repository-name django_uwsgi_nginx --force
    aws ecr delete-repository --repository-name django_uwsgi_django --force
    
    # IAM Role
    # djangoUwsgiEKSClusterRole
    aws iam list-attached-role-policies --role-name djangoUwsgiEKSClusterRole
    aws iam detach-role-policy --role-name djangoUwsgiEKSClusterRole --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
    aws iam delete-role --role-name djangoUwsgiEKSClusterRole

    # djangoUwsgiEKSNodeRole
    aws iam list-attached-role-policies --role-name djangoUwsgiEKSNodeRole
    aws iam detach-role-policy --role-name djangoUwsgiEKSNodeRole --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
    aws iam detach-role-policy --role-name djangoUwsgiEKSNodeRole --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
    aws iam detach-role-policy --role-name djangoUwsgiEKSNodeRole --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
    # インスタンスプロファイルの削除
    aws iam list-instance-profiles-for-role --role-name djangoUwsgiEKSNodeRole
    aws iam remove-role-from-instance-profile --instance-profile-name djangoUwsgiEKSNodeRole --role-name djangoUwsgiEKSNodeRole
    aws iam delete-role --role-name djangoUwsgiEKSNodeRole

    # VPC関連
    # vpc-idの確認
    aws ec2 describe-vpcs --filters "Name=tag:Name,Values=django-uwsgi-vpc" --query 'Vpcs[*].[VpcId,CidrBlock]' --output table
    # Network ACL
    aws ec2 describe-network-acls --filters "Name=vpc-id,Values=[VPC_ID]" --query 'NetworkAcls[*].[NetworkAclId]' --output table
    aws ec2 delete-network-acl --network-acl-id [NACL_ID]
    # SecurityGroup
    
    # Subnet
    # VPC
    aws ecw delete-vpc --vpc-id [VPC_ID]
    ```

以上
