## Redmine ContrastSecurity Plugin

### Steps
1. ContrastSecurityプラグインを配置  
  ```plugins/``` 直下にcontrastsecurityディレクトリを配置
2. ContrastSecurityプラグインをインストール  
  Redmineを再起動してください。とくにDBマイグレートや依存ライブラリのインストールは必要ありません。

3. RedmineのRestAPIを有効にする  
  管理 -> 設定 -> APIで、「RESTによるWebサービスを有効にする」にチェックを入れる。

3. TeamServerからwebhookを受けるユーザーのAPITokenを確認  
  個人設定 -> APIアクセスキーを表示で、APIトークンが表示されます。

4. TeamServerのGeneric Webhookを設定  
  - Name: ```Redmine（好きな名前）```  
  - URL: ```http://[REDMINE_HOST]:[REDMINE_PORT]/redmine/contrast/vote?key=[API_TOKEN]```  
    サブディレクトリを使っていない場合は
    ```http://[REDMINE_HOST]:[REDMINE_PORT]/contrast/vote?key=[API_TOKEN]```
  - Applications: ```任意```  
  - Payload:
    ```
    {
      "summary":"$Title",
      "description":"$Message",
      "project": "petclinic",
      "tracker": "脆弱性",
      "priority": "高"
    }
    ```
    project, tracker, priorityは連携するRedmine側の内容と合わせてください。  
    - プロジェクトには名称ではなく識別子を設定してください。  
    - 存在しないプロジェクト名が指定されていると、チケット作成時にエラーとなり、Webhook自体が無効となります。  
      その場合は、Payloadを修正のうえ接続テストからWebhookの保存をやりなおす必要があります。
    - トラッカーも適切に設定してください。  
    - プライオリティも設定してください。  
  - Send as HTML: ```チェックは外してください```
  
5. Generic Webhookの設定後、Notfication（ベルマーク）を行ってください。  
  Libraryも対象にすることでCVEを含むライブラリの情報もRedmineに連携されます。
