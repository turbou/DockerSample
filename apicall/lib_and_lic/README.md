### 概要
組織単位でライブラリの以下の情報をタブ区切りで出力します。  
- ライブラリ名
- ライセンス（複数の場合があるため、こちらをカンマ区切りにしています）
- 言語

### 前提条件
本スクリプトはMacおよびLinuxで動作を確認しています。  
動作にはjqが必要となります。

- [jq](https://stedolan.github.io/jq/) for JSON parse.
  
    ```bash
    # Mac
    brew install jq
    # CentOS
    yum -y install epel-release
    yum -y install jq
    # Ubuntu
    apt -y update
    apt -y install jq
    ```

### 環境変数をセット
エクスポートでもインポートでもスクリプト実行時に必要です。
```bash
export CONTRAST_BASEURL=https://eval.contrastsecurity.com/Contrast
export CONTRAST_API_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export CONTRAST_USERNAME=xxxxx.yyyyy@contrastsecurity.com
export CONTRAST_SERVICE_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export CONTRAST_ORG_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
```

### ライブラリの情報をエクスポート
```bash
./exp.sh
```
output.tsvが出力されます。  
Excelで開く際はタブを分割文字列として読み込んでください。

以上
