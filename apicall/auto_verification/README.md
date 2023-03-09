# 雛形組織の自動検証ポリシーの設定をエクスポート、インポートするスクリプト

## 事前準備

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
環境変数を何も設定していない状態でスクリプトを実行すると必要な環境変数が表示されます。  
```bash
export CONTRAST_BASEURL=https://eval.contrastsecurity.com/Contrast
export CONTRAST_API_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export CONTRAST_USERNAME=xxxxx.yyyyy@contrastsecurity.com
export CONTRAST_SERVICE_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export CONTRAST_ORG_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
```

## エクスポート

### 組織の自動検証ポリシーの設定をエクスポート
```bash
./auto-verification_exp.sh
```
remediation.jsonが出力されます。

## インポート
**（注意事項）**  
エクスポートされた同じファイルで繰り返しインポートを行うと、同名のポリシーは書き換えではなく  
どんどん重複して追加されていきますので、ご注意ください。

### エクスポートした自動検証ポリシーの設定ファイル（remediation.json）をインポート
インポート先の組織に合わせて、環境変数はセットし直してください。
```bash
./auto-verification_imp.sh
```

### エクスポートした自動検証ポリシーの設定ファイル（remediation.json）をEOP配下の全組織にインポート
- 上のexp, impと異なり、こちらでは組織ID（CONTRAST_ORG_ID）のセットは不要です。環境変数が残っていても問題はありません。
- この処理は全組織に対しての操作となるので、EOPの**SuperAdmin権限を持つユーザー**のUSERNAME, SERVICE_KEYを再セットしてください。  
```
EOP（オンプレ）版TeamServerでデフォルトで提供されるcontrast_superadmin@XXXXXX.xxxユーザーを指定しても良いですが  
別途、本処理専用のSuperAdmin権限を持つユーザーの作成をお勧めします。  
この処理によって、このユーザーは全組織に対してRulesAdmin組織権限が付与されるため、ある組織にログインして操作を行う
ユーザーの場合、TeamServerの操作に影響があります。
```
処理の流れとしては以下のとおりです。
- RulesAdminGroupという名前のグループを作成し、そこに今回接続するユーザーをメンバーとして紐付けます。  
さらに存在する全組織をこのグループにRulesAdmin組織権限メンバーとして紐付けます。
- そして、組織ごとにremediation.jsonの内容を反映していきます。
```bash
./all_org_auto-verification_imp.sh
```

処理終了後、EOP配下の各組織の自動検証ポリシー画面にて、反映結果をご確認ください。

以上
