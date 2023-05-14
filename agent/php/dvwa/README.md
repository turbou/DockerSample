# Docker + PHP7.4 + DVWA + Contrast Agent

## 事前準備
### contrast_security.yamlをDL

### DVWAの配置
#### git clone
```
git clone https://github.com/digininja/DVWA.git ./html/public
```
#### config準備
```
# DBホストが127.0.0.1になっているので、コンテナ名mysqlに置換(mysqlはdocker-compose.ymlのDBのサービス名)
cat ./html/public/config/config.inc.php.dist | sed "s/'127.0.0.1'/'mysql'/" > ./html/public/config/config.inc.php
```
## コンテナ起動
### Dockerビルド
```
docker-compose build --no-cache
```
### コンテナ起動
```
docker-compose up -d
```
## DVWAの設定
http://localhost:8080
### Setup
#### Database
メニューの**Setup / Reset DB**をクリックして、下のほうの **Create / Reset Database** をクリック
#### DVWA Security
メニューの**DVWA Security**をクリックして、`Security Level`をLowにしてSubmit

## テスト
#### SQL Injection
`1' or 'a'='a`と入力してSubmit

## オンボード確認
SQLインジェクションなどが検知されていることを確認
