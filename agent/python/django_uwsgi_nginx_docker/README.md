## OWASP Juice Shop をContrastエージェント付きのDockerコンテナで起動

### Dockerビルド
1. contrast_security.yamlを本物と入れ替えてください。  
  その他の必要な設定も施しておいてください。
2. Dockerビルド
    ```bash
    docker-compose build --no-cache
    ```

### コンテナ起動
1. コンテナ起動
    ```bash
    docker-compose up
    ```
2. Juice Shop確認
  http://localhost:3000 で確認
3. Contrastサーバでオンボード確認

以上
