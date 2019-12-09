## Mantis ContrastSecurity Plugin

### Steps
1. ContrastSecurityプラグインをインストール  
  管理者でログイン、管理 -> プラグインの管理からContrastSecurityプラグインをインストール  
  ４種類のカスタムフィールドも自動的に追加されます。

2. TeamServerからwebhookを受けるユーザーのAPITokenを生成  
  アカウント設定 -> APIトークンで適当な名前で生成

3. TeamServerのGeneric Webhookを設定  
  Name: ```Mantis（好きな名前）```  
  URL: ```http://[MANTIS_HOST]:[MANTIS_PORT]/api/rest/plugins/ContrastSecurity/services/[API_TOKEN]```  
  Applications: ```任意```  
  Payload:
    ```
    {
      "summary":"$Title",
      "description":"$Message",
      "category": {
        "name": "General"
      },
      "project": {
        "name": "petclinic"
      }
    }
    ```
    categoryとprojectは連携するMantis側の内容と合わせてください。  
    Send as HTML: ```チェックは外してください```
  
