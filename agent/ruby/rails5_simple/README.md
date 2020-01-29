## Rails5のDockerサンプル

#### プロジェクトフォルダを作成

```bash
mkdir rails_sample
```

#### Dockerfileを作成

```bash
vim Dockerfile
```

```dockerfile
FROM ruby:2.5.1
ENV LANG C.UTF-8
ARG http_proxy
ARG https_proxy

RUN apt-get update -qq && apt-get install -y \
    build-essential \
    nodejs \
 && rm -rf /var/lib/apt/lists/*

RUN gem install bundler

WORKDIR /tmp
ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
RUN bundle install

ENV APP_HOME /myapp
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME
ADD . $APP_HOME

```

#### docker-compose.ymlを作成

```bash
vim docker-compose.yml
```

```yaml
version: '3'

services:
  web:
    container_name: rails_sample.web
    build:
      context: .
      args:
        http_proxy: $HTTP_PROXY
        https_proxy: $HTTPS_PROXY
    env_file: .env
    ports:
      - "3000:3000"
    command: bundle exec rails s -p 3000 -b '0.0.0.0'
    volumes:
      - .:/myapp
      #- bundle:/usr/local/bundle
    depends_on:
      - db
  db:
    container_name: rails_sample.db
    image: mysql:5.7
    environment:
      MYSQL_ROOT_PASSWORD: password
    ports:
      - '3306:3306'
    volumes:
      - mysql_data:/var/lib/mysql

volumes:
  #bundle:
  mysql_data:

```

#### GemfileとGemfile.lockを作成

```bash
vim Gemfile
```

```properties
source 'https://rubygems.org'

ruby '2.5.1'

gem 'rails', '5.2.4.1'
gem 'mysql2', '>= 0.4.4', '< 0.6.0'

```

```bash
touch Gemfile.lock
```

#### Proxy経由の場合は.envも作成

```bash
vim .env
```

```properties
HTTP_PROXY=http://user:password@host:port
HTTP_PROXY=http://user:password@host:port
```

#### Railsアプリケーションを作成

```bash
docker-compose run web rails new . --force --database=mysql --skip-bundle
```

#### データベースの設定を反映

```database.yml
vim config/database.yml
```

```yaml
#
# And be sure to use new-style password hashing:
#   https://dev.mysql.com/doc/refman/5.7/en/password-hashing.html
#
default: &default
  adapter: mysql2
  encoding: utf8
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: root
  password: password    # ここと
  host: db              # ここを修正
```

#### Dockerビルド、DB作成、コンテナ起動

```bash
docker-compose build
docker-compose run web rails db:create
docker-compose up -d
```

### 補足

```bash
docker container prune
docker volume prune
docker image prune
docker network prune
```



以上

