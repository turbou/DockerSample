# PHPエージェントでLaravelアプリをオンボード

## 前準備
contrast_security.yaml をDLして、docker/app下に配置します。  
既にダミーのcontrast_security.yamlが置いてありますので、入れ替えてください。  
エージェントに対する追加の設定があれば追加しておいてください。  

docker/app下にDockerfileとDockerfile_bkがありますが、それぞれ起動させるサンプルアプリが異なります。  
```
Dockerfile: Basic Task List
https://laravel.com/docs/5.1/quickstart

Dockerfile_bk: bagisto
https://github.com/bagisto/bagisto
```
起動させたいサンプルのDockerfileのほうを有効にしてください。

## Dockerビルド
```bash
docker-compose build --no-cache
```

## 起動
```bash
docker-compose up -d
# Basic Task Listの場合
docker-compose exec app php artisan migrate
# bagistoの場合
docker-compose exec app php artisan bagisto:install
```

## アクセス
http://xxx.xxx.xxx.xxx:8089/  
にアクセスして、サンプルアプリにアクセス
TeamServerでオンボード確認
※ サーバ、アプリのオンボードとライブラリ情報まで確認できます。ルートカバレッジの情報はまだ取れていません。

## アプリを入れ替えるなどで、クリアする場合
```bash
docker-compose down
rm -fr ./data
# Dockerfileを入れ替えて
docker-compose build --no-cache
```
