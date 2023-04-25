# TeamServerをdocker composeで動かす

## 前提条件
- MacのDocker Desktopで動作確認済みです。
- 有効なContrastのライセンスファイルが必要です。

## 事前準備
docker-composeコマンドを実行するターミナルで環境変数 ```CONTRAST_LICENSE``` が設定されている必要があります。
```bash
export CONTRAST_LICENSE=$(cat /Users/turbou/Downloads/contrast-12-31-2023.lic)
```
*~/.bash_profileに上記をそのまま設定しておいてもよいです。*

## コンテナ起動
#### Dockerイメージプル
いきなりup -dでもよいですが、先にpullしたほうがなんとなく。
```bash
docker-compose pull
```
#### コンテナ起動
コンテナを起動します。
```bash
docker-compose up -d
```
## その他確認コマンド
#### 稼働確認
```bash
docker-compose ps
```
#### 個別のログを見る場合は
```bash
docker-compose logs -f --tail 100 nginx
docker-compose logs -f --tail 100 teamserver
docker-compose logs -f --tail 100 mysql
docker-compose logs -f --tail 100 mail
```
#### コンテナに入るには
```bash
docker exec -it contrast.teamserver bash
```

## 起動後の設定
### SMTPの設定


## コンテナ停止
```bash
docker-compose down
```

以上
