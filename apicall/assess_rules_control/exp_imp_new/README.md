## 概要
ある組織に設定されている**デフォルト**ASSESSルールのon/off設定を他の組織のデフォルトASSESSルールや既にオンボード済みのアプリケーションに一括で設定できます。  
- まず最初にベースとなる組織の**デフォルト**ASSESSルールのon/off設定をエクスポートします。  
  *assess_rules_exp.sh* を使用します。
- 特定の組織向けにエクスポートしたASSESSルールの設定内容を反映する場合  
  *assess_rules_imp.sh* を使用します。
- SuperAdminとして、全組織に対して対してエクスポートしたASSESSルールの設定内容を反映する場合  
  *all_org_assess_rules_imp.sh* を使用します。

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
### ベースとなる**デフォルト**ASSESSルールのon/off設定をエクスポートする場合
#### 環境変数をセット
```bash
export CONTRAST_BASEURL=https://eval.contrastsecurity.com/Contrast
export CONTRAST_USERNAME=xxxxx.yyyyy@contrastsecurity.com
export CONTRAST_SERVICE_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export CONTRAST_ORG_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
export CONTRAST_API_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```
#### スクリプトの実行
```bash
./assess_rules_exp.sh
```
スクリプトと同じ場所に *./rules.json* が出力されます。  
このファイルがASSESSルールのon/off設定のベースファイルとなるので削除しないでください。  
### 特定の組織向けにエクスポートしたASSESSルールの設定内容を反映する場合
#### 環境変数をセット
```bash
export CONTRAST_BASEURL=https://eval.contrastsecurity.com/Contrast
export CONTRAST_USERNAME=xxxxx.yyyyy@contrastsecurity.com
export CONTRAST_SERVICE_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export CONTRAST_ORG_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
export CONTRAST_API_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```
#### スクリプトの実行
```bash
# すべてのルールを有効にする場合
./assess_rules_imp.sh
```
#### SuperAdminとして、全組織（のアプリケーションすべて）に対して対してエクスポートしたASSESSルールの設定内容を反映する場合
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
./all_org_assess_rules_imp.sh
```
