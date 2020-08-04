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
```python
# これはDjango自体のシークレットキー
SECRET_KEY = 'r&id5o(ix9(yazvnxqt$c0*334l)l5bqgfbv#mf9%lojd#(7dn'

# TeamServerの設定
TEAMSERVER_URL = 'http://xxx.xxx.xxx.xxx:8080/Contrast'
# TeamServerのアカウントの認証情報
AUTHORIZATION = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX=='
API_KEY = 'XXXXXXXXXXXXXXXX'

# ここから下はBacklogの設定（BacklogのAPIキー自体はTeamServerのGeneric Webhookに記載します）
BACKLOG_URL = 'https://xxxxxxx.backlog.com'
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
```

### Djangoのマイグレートとスーパーユーザーの作成
```
```

### Backlogのチケット一括削除コマンド
```
docker exec -i django python /project/django_project/manage.py bulk_remove_backlog_issues --projectid XXXXX --apikey XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```
