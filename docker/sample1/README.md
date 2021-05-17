### コンテナ起動時にContrastエージェントをマウントするサンプル

```bash
docker-compose build --no-cache
```
TeamServerからJavaエージェントをDLして、Dockerfileと同じ位置に配置
```bash
docker-compose up -d
```
TeamServerにTomcat_Sampleがオンボードされていることを確認
