## Redmine ContrastSecurity Plugin

### Overview
- Contrast TeamServerからのWebhookを受信して、Redmineにチケットを作成することができます。  
  脆弱性、CVEを含むライブラリの情報がRedmineに共有されます。
- Redmineのチケットのステータスを変更すると、Contrast TeamServerに連携することができます。
- Contrast TeamServerで脆弱性のステータスが変更されると、これもWebhookでRedmineに通知され  
  Redmineのチケットのステータスも合わせて更新されます。
- コメントについても相互に共有されます。ステータス変更時のコメントも同様です。
- Redmineのチケットの詳細を表示する際に、Contrast TeamServerの以下の情報が自動で同期されます。  
  - 最終検出日時
  - 重大度（重大度に応じて、Redmineのチケットの優先度が同期されます）

### Steps
1. ContrastSecurityプラグインを配置  
  ```plugins/``` 直下にcontrastsecurityディレクトリを配置

2. マイグレート  
    ```bash
    # インストール時
    bundle exec rake redmine:plugins:migrate
    # アンインストール時は必要に応じて以下のコマンドを実行してください。
    bundle exec rake redmine:plugins:migrate VERSION=0 NAME=contrastsecurity
    ```
    Contrastプラグインのモデルを新たに作るわけではなく、デフォルトの選択肢（ステータス、優先度）、トラッカー、カスタムフィールドを作成します。

3. ContrastSecurityプラグインを有効にします。  
  Redmineを再起動してください。

4. RedmineのRestAPIを有効にする  
  管理 -> 設定 -> APIで、「RESTによるWebサービスを有効にする」にチェックを入れる。

5. TeamServerからwebhookを受けるユーザーのAPITokenを確認  
  個人設定 -> APIアクセスキーを表示で、APIトークンが表示されます。

6. TeamServerのGeneric Webhookを設定  
    - Name: ```Redmine（好きな名前）```  
    - URL: ```http://[REDMINE_HOST]:[REDMINE_PORT]/redmine/contrast/vote?key=[API_TOKEN]```  
      サブディレクトリを使っていない場合は
      ```http://[REDMINE_HOST]:[REDMINE_PORT]/contrast/vote?key=[API_TOKEN]```
    - Applications: ```任意```  
    - Payload:
      ```json
      {
        "summary":"$Title",
        "description":"$Message",
        "project": "petclinic",
        "tracker": "脆弱性",
        "application_name": "$ApplicationName",
        "application_code": "$ApplicationCode",
        "vulnerability_tags": "$VulnerabilityTags",
        "application_id": "$ApplicationId",
        "server_name": "$ServerName",
        "server_id": "$ServerId",
        "organization_id": "$OrganizationId",
        "severity": "$Severity",
        "status": "$Status",
        "vulnerability_id": "$TraceId",
        "vulnerability_rule": "$VulnerabilityRule",
        "environment": "$Environment",
        "event_type": "$EventType"
      }
      ```
      project, trackerは連携するRedmine側の内容と合わせてください。  
      - プロジェクトには名称ではなく識別子を設定してください。  
      - 存在しないプロジェクト名が指定されていると、チケット作成時にエラーとなり、Webhook自体が無効となります。  
        その場合は、Payloadを修正のうえ接続テストからWebhookの保存をやりなおす必要があります。
      - トラッカーも適切に設定してください。  
    - Send as HTML: ```チェックは外してください```  
  
    設定後、**テスト接続**を行って、保存してください。  
  
7. Generic Webhookの設定後、Notfication（ベルマーク）を行ってください。  
  Libraryも対象にすることでCVEを含むライブラリの情報もRedmineに連携されます。  
  「ステータス変更時に通知を受信」にチェックを入れることで、TeamServerのステータス変更についてもRedmine側に通知されます。（双方向同期）

8. プラグインの設定（確認）を行います。
    - TeamServer 接続設定  
      Contrast TeamServerのアカウントメニュー「あなたのアカウント」に必要な情報が揃ってるので、そこからコピーしてください。
    - チケット作成対象  
      チケットを作成する対象にチェックを入れてください。
    - ステータスマッピング  
      Contrast TeamServer側のステータスとRedmine側のステータスの紐付けを設定します。
    - 優先度マッピング  
      Contrast TeamServer側の脆弱性の**重大度**とRedmine側の**優先度**の紐付けを設定します。
