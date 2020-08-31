### Dockerビルド
```bash
docker-compose build --no-cache
```

### Djangoのローカル設定ファイル（local_settings.py）の作成
```bash
cd relay_django/relay_django/
vim local_settings.py
```
local_settings.pyの内容
シークレットキーは https://djecrety.ir/ などのサイトで適当に生成してください。
```python
# これはDjango自体のシークレットキー
SECRET_KEY = 'r&id5o(ix9(yazvnxqt$c0*334l)l5bqgfbv#mf9%lojd#(7dn'
```

### Djangoコンテナの起動ポートの変更（確認）
```bash
vim docker-compose.yml
```
8085のところを任意のポートに変更してください。
```yaml
version: '3' 

services:
  django:
    image: django:1.0.0
    build:
      context: ./django
    container_name: django
    restart: always
    command: python /project/django_project/manage.py runserver 0.0.0.0:8081
    volumes:
      - ./relay_django:/project/django_project
    ports:
      - "8085:8081"
```

### Djangoコンテナの起動
```bash
# docker-compose.ymlのある場所で
docker-compose up -d
# 同一ホストで複数コンテナを起動しようとしてrecreateされてしまう場合は
docker-compose -p taka up -d
```

### Djangoのマイグレートとスーパーユーザーの作成
```
docker exec -i django python /project/django_project/manage.py makemigrations relay_django
docker exec -i django python /project/django_project/manage.py migrate
docker exec -i django python /project/django_project/manage.py batch_createsuperuser --username admin --email xxxxx@contrastsecurity.com --password xxxxx
```

### Djangoへの接続
http://xxx.xxx.xxx.xxx:8085/admin/  
admin/xxxxx

### 各サービスごとの接続設定
http://xxx.xxx.xxx.xxx:8085/admin/relay_django/  
に接続して、Backlog, Gitlab, TeamServer設定を行ってください。  
基本的にBacklogかGitlab（またはその両方）の接続設定を作ってから  
TeamServerの接続設定にそれらを紐付ける感じです。  

### チケット一括削除コマンド
BacklogもGitlab Issueも基本、画面上ではチケットの一括削除が出来ませんが、以下のコマンドで一括削除することができます。  
`--name`に指定するのはBacklog, Gitlabの接続設定名です。
#### Backlog
一度に100件まで削除できるので、チケットが0になるまで繰り返してください。  
```
docker exec -i django python /project/django_project/manage.py bulk_remove_backlog_issues --name XXXXX
```
#### Gitlab
一度に20件まで削除できるので、チケットが0になるまで繰り返してください。
```
docker exec -i django python /project/django_project/manage.py bulk_remove_gitlab_issues --name XXXXX
```
