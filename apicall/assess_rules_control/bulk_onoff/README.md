## 概要
アプリケーションごとに設定されているASSESSルールのon/offを一括処理で設定できます。  
- 特定の組織（のアプリケーションすべて）に対して一括処理を行う場合  
  *assess_rules_bulk_onoff.sh* を使用します。
- SuperAdminとして、全組織（のアプリケーションすべて）に対して一括処理を行う場合  
  *all_org_assess_rules_bulk_onoff.sh* を使用します。

それぞれ目的に応じて使用するスクリプトを選択してください。  

## 前提条件
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

## 使い方
### 特定の組織（のアプリケーションすべて）に対して一括on/off設定を行う場合
#### 環境変数をセット
```bash
export CONTRAST_BASEURL=https://eval.contrastsecurity.com/Contrast
export CONTRAST_API_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export CONTRAST_USERNAME=xxxxx.yyyyy@contrastsecurity.com
export CONTRAST_SERVICE_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export CONTRAST_ORG_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
```
#### スクリプトの実行
```bash
# すべてのルールを有効にする場合
./assess_rules_bulk_on.sh --mode on
# すべてのルールを無効にする場合
./assess_rules_bulk_on.sh --mode off
```
スクリプトの引数について
- -m または --mode で、on/offを指定します。

#### SuperAdminとして、全組織（のアプリケーションすべて）に対して一括on/off設定を行う。
#### 環境変数をセット
```bash
export CONTRAST_BASEURL=https://eval.contrastsecurity.com/Contrast
export CONTRAST_API_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export CONTRAST_USERNAME=xxxxx.yyyyy@contrastsecurity.com
export CONTRAST_SERVICE_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# !!注意!!CONTRAST_USERNAME, CONTRAST_SERVICE_KEYはSuperAdmin権限を持つユーザーとしてください。
```
#### スクリプトの実行
```bash
# すべてのルールを有効にする場合
./all_org_assess_rules_bulk_onoff.sh --mode on
# すべてのルールを無効にする場合
./all_org_assess_rules_bulk_onoff.sh --mode off
```
スクリプトの引数について
- -m または --mode で、on/offを指定します。
