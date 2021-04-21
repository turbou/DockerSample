### 環境変数をセット
エクスポートでもインポートでもスクリプト実行時に必要です。
```bash
export CONTRAST_BASEURL=https://eval.contrastsecurity.com/Contrast
export CONTRAST_API_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export CONTRAST_USERNAME=xxxxx.yyyyy@contrastsecurity.com
export CONTRAST_SERVICE_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export CONTRAST_ORG_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
```

### 組織のASSESSルールの設定をエクスポート
```bash
./severity_exp.sh
```
rules.jsonが出力されます。

### エクスポートしたASSESSルールの設定ファイル（rules.json）をインポート
インポート先の組織に合わせて、環境変数はセットし直してください。
```bash
./severity_imp.sh
```

### エクスポートしたASSESSルールの設定ファイル（rules.json）をEOP配下の全組織にインポート
上のexp, impと異なり、こちらでは組織ID（CONTRAST_ORG_ID）のセットは不要です。  
ですが、全組織に対しての操作となるので、EOPのSuperAdmin権限を持つユーザーのUSERNAME, SERVICE_KEYをセットしてください。  
処理の流れとしては以下のとおりです。
- RulesAdminGroupという名前のグループを作成し、そこに今回接続するユーザーをメンバーとして紐付けます。  
さらに存在する全組織をこのグループに紐付けます。
- そして、組織ごとにrules.jsonの内容を反映していきます。
```bash
./all_org_severity_imp.sh
```

以上
