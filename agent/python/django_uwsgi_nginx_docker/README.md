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
2. Djangoアプリ接続確認
  http://localhost:8000 で確認（管理サイトは http://localhost:8000/admin ）
3. Contrastサーバでオンボード確認

以上
