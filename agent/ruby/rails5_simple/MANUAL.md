## Rails5のDockerサンプル(Contrastエージェント付き)

### 前提

#### バージョン

```
Ruby 2.5.1
Rails 5.2.4.1
```

#### バージョンを変更する場合

Rubyの場合はDockerfileの下の箇所を変更

```dockerfile
FROM ruby:2.5.1
```

Railsの場合はGemfileの下の箇所を変更

```
gem "rails", "5.2.4.1"
```

------

### 動かしてみる

#### フォルダに移動

```bash
cd ContrastSecurity/agent/ruby/rails5_simple/
# 中身を確認
ls -l
-rw-r--r--  1 turbou  staff       446  2  2 02:00 Dockerfile
-rw-r--r--  1 turbou  staff       155  2  2 02:34 Gemfile
-rw-r--r--  1 turbou  staff         0  2  2 02:12 Gemfile.lock
-rw-r--r--@ 1 turbou  staff      1328  2  2 02:35 MANUAL.md
-rwxr-xr-x  1 turbou  staff       219  2  2 02:12 clear.sh
-rw-r--r--@ 1 turbou  staff         0  2  2 01:03 contrast-agent-3.5.0.gem # これを本物にする
-rw-r--r--@ 1 turbou  staff         0  1 31 02:30 contrast_security.yaml   # これも本物にする
-rw-r--r--  1 turbou  staff       527  2  2 01:24 docker-compose.yml
```

*エージェントと設定ファイルをTeamServerから落として上記のダミーファイルと入れ替えてください。*

エージェントのバージョンを変える場合は、Dockerfileの中身のバージョンも修正してください。

```dockerfile
COPY contrast-agent-3.5.0.gem /tmp/contrast-agent-3.5.0.gem
RUN gem install contrast-agent-3.5.0.gem
```

#### Railsアプリケーションフォルダを生成

```bash
docker-compose run web rails new . --force --database=mysql --skip-bundle --skip
```

#### データベースの接続先修正

```bash
vim config/database.yml
```

```yaml
default: &default
  adapter: mysql2
  encoding: utf8
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: root
  password: password # ここと
  host: db           # ここをこのように変更
```

#### コントラストが効くように修正

```bash
vim Gemfile
```

以下をGemfileの末尾に追加して保存

```
group :contrast, :development, :test, :production do
    gem 'contrast-agent'
end
```

#### Dockerビルド

```bash
docker-compose build
# すっきりしない時は
docker-compose build --no-cache
```

#### テーブルの生成

```bash
docker-compose run web rake db:create
```

#### Railsコンテナの起動

```bash
docker-compose up -d
```

##### 接続確認

```
http://localhost:3000/
```



#### 補足

##### サンプルフォルダの中身をクリア（リセット）する場合は

```bash
./clear.sh
```

Railsアプリケーションフォルダや.gitフォルダなどがクリアされます。

Gemfile, Gemfile.lockなども元に戻ります。

##### Dockerコンテナのクリーンアップ

```bash
docker-compoes down # でも基本クリアされますが
docker container prune
docker volume prune
docker image prune
docker network prune
# すべてYesで削除してください。
```



以上

