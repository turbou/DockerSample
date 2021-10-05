# Elastic BeanstalkでPetClinicを動かしてみる

## 前提条件
- この手順ではEB CLIを使います。事前にインストールと設定を済ませてください。

## このフォルダの位置と初期ファイル

```
ContrastSecurity/demo/elasticbeanstalk
```

初期状態は以下のとおりです。

```bash
├── .ebextensions
│   └── contrast.config
├── Procfile
└── README.md # このREADME.mdです。
```

各ファイルの中身は以下のとおりです。

.ebextensions/contrast.config

```yaml
container_commands:
  01_make_contrast_dir:
    command: "sudo mkdir -p /opt/contrast"
  02_copy_contrast_agent:
    command: "yes | sudo cp .ebextensions/contrast.jar /opt/contrast/contrast.jar"
```

Procfile

```yaml
web: java -javaagent:/opt/contrast/contrast.jar -Dcontrast.server.name=ElasticBeanstalk -Dcontrast.agent.java.standalone_app_name=PetClinic_EB -jar spring-petclinic-1.5.1.jar --server.port=5000
```

## 必要なものを配置

- ContrastエージェントをTeamServerからダウンロードして ```.ebextensions``` の下に配置します。
- PetClinicのjar（ここでは*spring-petclinic-1.5.1.jar*）をProcfileと同じ階層に配置します。
  *spring-petclinic-1.5.1.jar* のビルドについては割愛します。
  jarの名前が異なる場合はProcfileの-jarの名前も合わせて変更してください。

この時点でのフォルダ、ファイル階層は以下のとおりです。

```bash
├── .ebextensions
│   ├── contrast.config
│   └── contrast.jar # エージェント
├── Procfile
├── README.md
└── spring-petclinic-1.5.1.jar # ターゲットのPetClinicアプリケーション
```

## AWSの操作手順

#### アプリケーションの作成

```bash
# 先にプラットフォームを確認する場合は
eb platform list -r ap-northeast-1
# アプリケーションの作成（--profileの指定は任意です）
eb init petclinic-demo --region ap-northeast-1 --platform corretto-8 --profile contrastsecurity
```

これによって ```.elasticbeanstalk/config.yml``` が生成されます。

config.ymlにdeploy定義を追加します。

```bash
vim .elasticbeanstalk/config.yml
```

以下を最下行に追加

```yaml
deploy:
  artifact: petclinic.zip
```

##### petclinic.zipを作成

```bash
zip -r petclinic.zip spring-petclinic-1.5.1.jar .ebextensions Procfile
```

##### 環境の作成

```bash
eb create petclinic-demo-env -s
```

- -s オプションはELBを作らずにシングルインスタンスとするオプションです。

成功すると下のように出力されます。

```bash
INFO    Successfully launched environment: petclinic-demo-env
```

とくに問題なく環境が作られたら、AWSマネジメントコンソールのElastic Beanstalkのアプリケーション一覧でpetclinic-demoをクリックして

URLをクリックでPetClinicを開けます。あとはTeamServerでPetClinic_EBがアプリケーションとしてオンボードされてることを確認します。

## その他補足

##### 再デプロイする場合ははzipを作り直して

```bash
zip -r petclinic.zip spring-petclinic-1.5.1.jar .ebextensions Procfile
eb deploy
```

##### sshで入る場合は

```bash
eb ssh --setup
# setupでキーペアを指定するなどしてから
eb ssh
```

以上

