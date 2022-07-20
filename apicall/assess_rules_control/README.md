### 概要
組織内のアプリケーションごとのASSESSルールのon/offを一括処理で設定できます。  

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
```bash
export CONTRAST_BASEURL=https://eval.contrastsecurity.com/Contrast
export CONTRAST_API_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export CONTRAST_USERNAME=xxxxx.yyyyy@contrastsecurity.com
export CONTRAST_SERVICE_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export CONTRAST_ORG_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
```

### 組織内のアプリケーションごとのASSESSルールのon/offを一括処理で設定
```bash
./assess_rules_bulk_on.sh -m on
```
スクリプトの引数について
- -m または --mode で、on/offを指定します。

以上
