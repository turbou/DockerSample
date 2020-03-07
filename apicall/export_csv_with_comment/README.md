### 前提

Python3.8.1でテストしています。Python3系なら動くと思います。

requirements.txt 

```
requests==2.23.0
```

```bash
python install -r ./requirements.txt
```

### 事前準備

環境変数をセットしてください。

```bash
export CONTRAST_BASEURL=https://eval.contrastsecurity.com/Contrast
export CONTRAST_AUTHORIZATION=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX==
export CONTRAST_API_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export CONTRAST_ORG_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
```

アプリケーションを指定する場合は以下の環境変数もセットしてください。

```bash
export CONTRAST_APP_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
```

### 実行方法

```bash
python ./sample.py > result.csv
```

