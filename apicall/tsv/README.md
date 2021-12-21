### スクリプト概要
EOPのSuperAdminユーザーで、EOP内の全組織の2段階認証の設定状態の取得するスクリプトと  
指定した組織への2段階認証の一括設定を行うスクリプトの2本です。

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
CONTRAST_USERNAMEとCONTRAST_SERVICE_KEYはSuperAdminユーザーの情報が必要です。

### 各組織の2段階認証の設定状態をエクスポート
```bash
./tsv_exp.sh
```
tsv.txtが出力されます。tsv.txtをcatするなどして、各組織の2段階認証の設定状態を確認してください。

### 特定の組織（複数可）に対して、2段階認証の設定を設定します。
上記のエクスポートの際に出力された```orgid_apikey_map.txt```を編集して、2段階認証を設定する  
組織だけ残して、不要な行を削除します。
```bash
./tsv_set.sh -e true -r false
```
スクリプトの引数について
- -e は2段階認証の有効/無効を指定します。
- -r は2段階認証を各ユーザー必須とするか任意とするかを指定します。

処理終了後、再度、```tsv_exp.sh```を実行するか、EOP配下の各組織の2段階認証の設定画面にて、反映結果をご確認ください。

以上
