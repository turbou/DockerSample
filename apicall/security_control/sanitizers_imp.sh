#!/bin/bash

usage() {
  cat <<EOF
  Usage: $0 [options]

  -a| --auth      認証情報json
  -i|--input      一括登録例外json
  -s|--skeleton   jsonスケルトンファイル生成
EOF
}

usage_full() {
  cat <<EOF
  Usage: $0 [options]

  -a| --auth      認証情報json
  -i|--input      一括登録例外json
  -s|--skeleton   jsonスケルトンファイル生成

  ルール一覧は以下の通りです。jsonのrulesには右側の値を指定してください。
    DynamoDBのNoSQLインジェクション           : nosql-injection-dynamodb
    ELインジェクション                        : expression-language-injection
    HQLインジェクション                       : hql-injection
    LDAPインジェクション                      : ldap-injection
    NoSQLインジェクション                     : nosql-injection
    OSコマンドインジェクション                : cmd-injection
    SMTPインジェクション                      : smtp-injection
    SQLインジェクション                       : sql-injection
    XML外部実体参照(XXE)                      : xxe
    XPathインジェクション                     : xpath-injection
    クロスサイトスクリプティング              : reflected-xss
    サーバサイドリクエストフォージェリ(SSRF)  : ssrf
    パストラバーサル                          : path-traversal
    リフレクションインジェクション            : reflection-injection
    任意に実行されるサーバサイドの転送        : unvalidated-forward
    信頼できないストリームでのreadLineの使用  : unsafe-readline
    信頼できないデータのデシリアライゼーション: untrusted-deserialization
    信頼境界線違反                            : trust-boundary-violation
    安全ではないXMLデコード                   : unsafe-xml-decode
    未検証のリダイレクト                      : unvalidated-redirect
    格納型クロスサイトスクリプティング        : stored-xss
EOF
}

generate_skeleton() {
  cat <<EOF > ./auth_skeleton.json
{
  "CONTRAST_URL": "",
  "API_KEY": "",
  "ORG_ID": "",
  "AUTH_HEADER": ""
}
EOF
  cat <<EOF > ./sanitizers_skeleton.json
[
  {
    "all_rules": true,
    "api": "jp.co.contrast.foo(java.lang.String*)",
    "language": "Java",
    "name": "Sanitaizer_foo",
    "rules": []
  },  
  {
    "all_rules": true,
    "api": "jp.co.contrast.bar(java.lang.String*)",
    "language": "Java",
    "name": "Sanitaizer_bar",
    "rules": []
  }
]
EOF
}

AUTH_JSON=
INPUT_JSON=
while getopts aish-: opt; do
  optarg="${!OPTIND}"
  [[ "$opt" = - ]] && opt="-$OPTARG"
  case "-$opt" in
    -a|--auth)
      AUTH_JSON="$optarg"
      shift
      ;;
    -i|--input)
      INPUT_JSON="$optarg"
      shift
      ;;
    -s|--skeleton)
      generate_skeleton
      echo "スケルトンjsonファイルを生成しました。"
      exit 0
      ;;
    -h|--help)
      usage_full
      exit 0
      ;;
    --)
      break
      ;;
    -\?)
      exit 1
      ;;
    --*)
      usage
      exit 1
      ;;
  esac
done

if [ -z "$AUTH_JSON" -o -z "$INPUT_JSON" ]; then
  usage
  exit 1
fi

BASE_URL=`cat ${AUTH_JSON} | jq -r '.CONTRAST_URL'`
ORG_ID=`cat ${AUTH_JSON} | jq -r '.ORG_ID'`
API_KEY=`cat ${AUTH_JSON} | jq -r '.API_KEY'`
AUTHORIZATION=`cat ${AUTH_JSON} | jq -r '.AUTH_HEADER'`
API_URL="${BASE_URL}/api/ng"

JSON_FILE=`cat ${INPUT_JSON}`
JSON_LENGTH=`echo ${JSON_FILE} | jq length`

for i in `seq 0 $(expr ${JSON_LENGTH} - 1)`; do
  name=`echo ${JSON_FILE} | jq -r .[${i}].name`
  language=`echo ${JSON_FILE} | jq -r .[${i}].language`
  api=`echo ${JSON_FILE} | jq -r .[${i}].api`
  all_rules=`echo ${JSON_FILE} | jq -r .[${i}].all_rules`
  rules_str=`echo ${JSON_FILE} | jq -r .[${i}].rules | sed -e 's/\[//g' -e 's/\]//g'`
  rules=""
  if [ "$rules_str" != "null" ]; then
    while read -r RULE_NAME; do
      echo ${RULE_NAME}
      rules="${rules}\"${RULE_NAME}\","
    done < <(echo ${JSON_FILE} | jq -r .[${i}].rules[])
    rules=`echo ${rules} | sed 's/,$//'`
  fi
  curl -X POST -sS \
    ${API_URL}/${ORG_ID}/controls/sanitizers?expand=skip_links \
    -H "Authorization: ${AUTHORIZATION}" \
    -H "API-Key: ${API_KEY}" \
    -H "Content-Type: application/json" \
    -H 'Accept: application/json' \
    -d '{"name":"'$name'","api":"'$api'","language":"'$language'","all_rules":'$all_rules',"rules":['$rules']}'
done

exit 0

