### 概要

TeamServerから脆弱性一覧を取得して、取得した情報からJiraのチケットに表形式のコメントを追加するPython版サンプルスクリプトです。

### 前提

Python3.12.5でテストしています。Python3系なら動くと思います。  
その他、必要なライブラリは以下のとおりです。
```bash
certifi==2024.8.30
charset-normalizer==3.3.2
idna==3.10
requests==2.32.3
urllib3==2.2.3
```

### 事前準備

環境変数をセットしてください。
情報はTeamServerのユーザーメニュー - ユーザーの設定 - プロファイルから取得できます。
```bash
export CONTRAST_BASEURL=https://eval.contrastsecurity.com/Contrast
export CONTRAST_AUTHORIZATION=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX==
export CONTRAST_API_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export CONTRAST_ORG_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
export CONTRAST_APP_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
```
また、コメントを書き込むJiraの認証情報とチケットIDも設定してください。
```bash
export CONTRAST_JIRA_USER=xxxx.yyyy@contrastsecurity.com
export CONTRAST_JIRA_API_TOKEN=YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
export CONTRAST_JIRA_TICKET_ID=FAKEBUG-12730
```

セッションメタデータで脆弱性をフィルタリングする場合は以下のように環境変数も設定してください。
```bash
export CONTRAST_METADATA_LABEL=branchName
export CONTRAST_METADATA_VALUE=feature/dev-001
```

### 実行方法

```bash
python ./add_comment.py
```

以上
