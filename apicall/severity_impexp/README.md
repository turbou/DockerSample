#### 環境変数をセット
エクスポートでもインポートでもスクリプト実行時に必要です。
```bash
export CONTRAST_BASEURL=https://eval.contrastsecurity.com/Contrast
export CONTRAST_API_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export CONTRAST_USERNAME=xxxxx.yyyyy@contrastsecurity.com
export CONTRAST_SERVICE_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export CONTRAST_ORG_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
```

#### 組織のASSESSルールの設定をエクスポート
```bash
./severity_exp.sh
```
rules.jsonが出力されます。

#### エクスポートしたASSESSルールの設定ファイル（rules.json）をインポート
インポート先の組織に合わせて、環境変数はセットし直してください。
```bash
./severity_imp.sh
```

以上
