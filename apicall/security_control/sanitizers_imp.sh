#!/bin/bash

usage() {
  cat <<EOF
  Usage: $0 [options]

  -a|--aut h      認証情報json
  -i|--input      一括登録例外json
  -d|--delete     既存のセキュリティ制御をインポート前にクリア
  -p|--prefix     インポート前クリアで残すルール名の接頭辞
  -s|--skeleton   jsonスケルトンファイル生成
EOF
}

usage_full() {
  cat <<EOF
  Usage: $0 [options]

  -a|--auth       認証情報json
  -i|--input      一括登録例外json
  -d|--delete     既存のセキュリティ制御をインポート前にクリア
  -p|--prefix     インポート前クリアで残すルール名の接頭辞
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
DEL_FLG=0
PREFIX=
while getopts aidpsh-: opt; do
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
    -d|--delete)
      DEL_FLG=1
      ;;
    -p|--prefix)
      PREFIX="$optarg"
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

EXISTING_SANITIZERS_JSON="./existing_sanitizers.json"

if [ ${DEL_FLG} -gt 0 ]; then
  rm -f ${EXISTING_SANITIZERS_JSON}
  curl -X GET -sS \
    ${API_URL}/${ORG_ID}/controls \
    -d expand=skip_links -d quickFilter=ALL \
    -H "Authorization: ${AUTHORIZATION}" \
    -H "API-Key: ${API_KEY}" \
    -H 'Accept: application/json' -J -o ${EXISTING_SANITIZERS_JSON}

  success=`cat ${EXISTING_SANITIZERS_JSON} | jq -r .success`
  if [ "${success}" != "true" ]; then
    echo "セキュリティ制御の一覧取得に失敗しました。"
    exit 1
  fi
  SANI_JSON_FILE=`cat ${EXISTING_SANITIZERS_JSON}`
  SANI_JSON_LENGTH=`echo ${SANI_JSON_FILE} | jq '.controls | length'`
  if [ ${SANI_JSON_LENGTH} -gt 0 ]; then
    for i in `seq 0 $(expr ${SANI_JSON_LENGTH} - 1)`; do
      id=`echo ${SANI_JSON_FILE} | jq -r .controls[${i}].id`
      name=`echo ${SANI_JSON_FILE} | jq -r .controls[${i}].name`
      if [ "${PREFIX}" != "" ]; then
        if [[ "${name}" =~ ^${PREFIX}* ]]; then
          echo "match" ${name}
          continue
        fi
      fi
      curl -X DELETE -sS \
        ${API_URL}/${ORG_ID}/controls/${id}?expand=skip_links \
        -H "Authorization: ${AUTHORIZATION}" \
        -H "API-Key: ${API_KEY}" \
        -H 'Accept: application/json' -J -o group_del.json
    done
  fi
fi

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

