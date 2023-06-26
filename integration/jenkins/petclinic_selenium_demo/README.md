## JenkinsでPetClinicを動かして、Seleniumでテスト

### 概要

DockerでJenkinsとSeleniumを稼働させます。

あとはJenkinsからジョブを実行すると、PetClinicの起動から、SeleniumのSQLインジェクションを行い、最後にContrastのJenkinsプラグインからTeamServerに問い合わせを行い、ASSESSの結果を取得します。

### プロジェクトの取得と起動

```bash
git clone https://github.com/turbou/ContrastSecurity.git
cd ContrastSecurity/integration/jenkins/petclinic_selenium_demo/
docker-compose build --no-cache
docker-compose up -d
```

http://localhost:9000/jenkins にアクセス

初回起動時に```Administrator password```と表示されたら下のコマンドでパスワードを取得してください。  
```bash
docker exec -it petclinic_demo.jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```
次のプラグインインストール画面については、右上のバツでそのまま何もせず終了してください。  

アクセスすると既にPetClinic_Seleniumというジョブがあります。

### ContrastのJenkinsプラグインのセットアップ

http://localhost:9000/jenkins/configure にアクセス

**Contrast Connections** の項目を設定して、Test Contrast Connectionを実行して疎通確認。

-  Connection Name
  ここは`Demo`としてください。Jenkinsジョブから`Demo`という名前で参照されるようにしています。
- Contrast Username
  TeamServerのログインID（メアド）
- Contrast API Key, Contrast Service Key, Organization ID
  あなたのアカウントから取得してください。
- Contrast URL
  https://eval.contrastsecurity.com/Contrast/api のように末尾に/apiが必要です。
- Result of a vulnerable build
  FAILURE
- チェックボックス２つは両方ともオンにする。

Test Contrast Connectionを実行して、Successfully connected to Contrast. と出ればOK

設定の保存も忘れずに行ってください。

### エージェントの準備とセットアップ

./petclinic_selenium_demo/contrast下にcontrast.jarをDL

yamlのDLは任意です。yamlを使用する場合は適宜、./petclinic/startup.sh を弄ってください。

一応、こんな感じになっています。

```bash
#!/bin/sh
if [ $# -eq 1 ]; then
    APP_VERSION=${1}
fi
java -javaagent:/tmp/contrast/contrast.jar \
-Dcontrast.server.environment=development \
-Dcontrast.server.name=MacBookPro \
-Dcontrast.agent.java.standalone_app_name=PetClinic_8001 \
-Dcontrast.application.version=${APP_VERSION} \
-Dcontrast.agent.contrast_working_dir=contrast-8001/ \
-Dcontrast.agent.logger.level=INFO \
-Dcontrast.agent.polling.app_activity_ms=3000 \
-Dcontrast.agent.polling.server_activity_ms=3000 \
-Dcontrast.api.timeout_ms=1000 \
-jar /tmp/petclinic/spring-petclinic-1.5.1.jar --server.port=8001
```

変更すべきところは以下２点です。

- contrast.agent.java.standalone_app_name
  アプリケーション名を任意のものに設定してください。
  **Jenkinsのジョブにもアプリケーション名を設定する箇所があるので、そちらも修正してください。**
- contrast.server.name
  適当な名前に設定してください。

任意変更箇所は以下です。

- --server.port
  デフォルトでは8001としています。変更する場合は**docker-compose.ymlのports**も合わせて
  修正してください。

### テストを実行してみる

#### VNCでseleniumの動きを見る場合

Finderで、CMD+Kで、vnc://localhost:5900に接続。パスワードは secret です。

#### ジョブを動かしてみる

1. 改めて、http://localhost:9000/jenkins/job/PetClinic_Selenium/ にアクセス
2. 脆弱性判定のしきい値はジョブの設定のContrastの箇所で弄ってください。
   このサンプルではMedium以上の脆弱性が１つでもあればビルド失敗としています。
3. ビルド実行を行う。
   ちょっと無駄にsleepとか入ってるので時間かかりますが、放っておくと、VNCにchromeが立ち上がってPetClinicに対してSQLインジェクションを実行します。

### Seleniumテストのカスタマイズについて

シナリオの作成方法配下です。

まず、https://chrome.google.com/webstore/detail/selenium-ide/mooikfkahbdckldjjndioackbalphokd?hl=ja

をchromeに入れます。

あとは普通に立ち上げたPetClinicに対して、通常の操作を行い実行を記録します。

そのまま保存すると.slide拡張子のファイルになりますが、テストの３点リーダをクリックしてExportを選択します。

**pytestを使っているので、Python pytestを選択。あとSeleniumGrid形式なので、Export for use on Selenium Gridのチェックボックスにチェックを入れて、Exportします。**

このファイルを./seleniumの下に置いて、あとはジョブの定義を変更すればテストシナリオをカスタマイズできます。

ジョブの定義は下のような感じです。

```bash
cd /tmp
/tmp/petclinic/startup.sh $BUILD_NUMBER &
sleep 210
pytest /tmp/selenium/test_sQLInjection.py
sleep 30
PID=`jps -l | awk '/spring-petclinic-1.5.1.jar/ {print $1}'`
kill -9 $PID

exit 0
```

### 補足
- Jenkinsジョブのconfig.xmlを直接弄って、docker-compose buildからやり直してDockerイメージを作り直した場合は  
  `jenkins_docker/`ディレクトリを削除してから、docker-compose up -dを実行してください。
- Jenkinsジョブの脆弱性しきい値設定で脆弱性タイプをALLにすると、うまく脆弱性の情報を取得することができないため  
  HQLインジェクションで設定しています。

以上

