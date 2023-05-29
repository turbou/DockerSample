# Contrast-Security-OSS/vulnpy の補足

## 事前準備
### vlunpyをgit clone
適当な場所に  
```bash
git clone https://github.com/Contrast-Security-OSS/vulnpy.git
```
### contrast_security.yamlをDL
python版のcontrast_security.yamlをgit cloneした```vulnpy```直下にダウンロードしてください。

### Docker関連ファイルをコピー
下の４ファイルを```vulnpy```の下にコピー
- Dockerfile_falcon
- Dockerfile_fastapi
- falcon.yml
- fastapi.yml

## Dockerで起動、オンボードしてみる
```vulnpy```の下で作業します。  
### Dockerビルド
1. Dockerビルド
    ```bash
    # Falcon
    docker-compose -f falcon.yml build --no-cache
    # FastAPI
    docker-compose -f fastapi.yml build --no-cache
    ```

### コンテナ起動
1. コンテナ起動
    ```bash
    # Falcon
    docker-compose -p falcon -f falcon.yml up -d
    # FastAPI
    docker-compose -p fastapi -f fastapi.yml up -d
    ```
2. 接続確認
  - Falcon  
    http://localhost:3010
  - FastAPI
    http://localhost:3011
3. Contrastサーバでオンボード確認

以上
