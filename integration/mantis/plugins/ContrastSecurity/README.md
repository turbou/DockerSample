## Mantis ContrastSecurity Plugin

### Steps
1. ContrastSecurityプラグインを配置  
  ```html/plugins/``` 直下にContrastSecurityディレクトリを配置
2. ContrastSecurityプラグインをインストール  
  管理者でログイン、管理 -> プラグインの管理からContrastSecurityプラグインをインストール  
  ４種類のカスタムフィールドも自動的に追加されます。

3. TeamServerからwebhookを受けるユーザーのAPITokenを生成  
  アカウント設定 -> APIトークンで適当な名前で生成

4. TeamServerのGeneric Webhookを設定  
  - Name: ```Mantis（好きな名前）```  
  - URL: ```http://[MANTIS_HOST]:[MANTIS_PORT]/api/rest/plugins/ContrastSecurity/services/[API_TOKEN]```  
  - Applications: ```任意```  
  - Payload:
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
    - プロジェクトに存在しないカテゴリを指定すると、グローバルカテゴリが採用されます。
    - プロジェクト名は日本語でも大丈夫です。
    - 存在しないプロジェクト名が指定されていると、Issue作成時にエラーとなり、Webhook自体が無効となります。
      その場合は、Payloadを修正のうえ接続テストからWebhookの保存をやりなおす必要があります。
  - Send as HTML: ```チェックは外してください```
  
5. Generic Webhookの設定後、Notfication（ベルマーク）を行ってください。  
  Libraryも対象にすることでCVEを含むライブラリの情報もMantisに連携されます。
