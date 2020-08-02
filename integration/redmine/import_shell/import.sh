#!/bin/bash

if [ -z "$CONTRAST_BASEURL" -o -z "$CONTRAST_AUTHORIZATION" -o -z "$CONTRAST_API_KEY" -o -z "$CONTRAST_ORG_ID" -o -z "$CONTRAST_APP_NAME" ]; then
  echo '環境変数が設定されていません。'
  echo 'CONTRAST_BASEURL       : https://(app|eval).contrastsecurity.com/Contrast/'
  echo 'CONTRAST_AUTHORIZATION : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX=='
  echo 'CONTRAST_API_KEY       : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
  echo 'CONTRAST_ORG_ID        : XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'
  echo 'CONTRAST_APP_NAME      : PetClinic_8001'
  echo 'REDMINE_BASEURL        : https://XXXXXXXXXXX/redmine'
  echo 'REDMINE_API_KEY        : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
  echo 'REDMINE_PROJECT_ID     : contrastsecurity'
  exit 1
fi

BASEURL=$CONTRAST_BASEURL
API_KEY=$CONTRAST_API_KEY
AUTHORIZATION=$CONTRAST_AUTHORIZATION
ORG_ID=$CONTRAST_ORG_ID
API_URL="${BASEURL}api/ng/${ORG_ID}"
APP_NAME=$CONTRAST_APP_NAME
RM_BASEURL=$REDMINE_BASEURL
RM_API_KEY=$REDMINE_API_KEY
#RM_PROJ_ID=$REDMINE_PROJECT_ID

rm -f ./applications.json
curl -X GET -sS \
  ${API_URL}/applications?expand=skip_links \
  -H "Authorization: ${AUTHORIZATION}" \
  -H "API-Key: ${API_KEY}" \
  -H 'Accept: application/json' -J -o applications.json

if [ -s ./applications.json ]; then
  SUCCESS=`cat ./applications.json | jq -r '.success'`
  if [ "${SUCCESS}" != "true" ]; then
    echo "アプリケーション一覧の取得に失敗しました。権限などをご確認ください。"
    exit 1
  fi
else
  echo "Authorizationヘッダ, APIキー, 組織ID, TeamServerのURLが正しいか、ご確認ください。"
  echo "接続先URL: " $API_URL
  exit 1
fi

cat ./applications.json | jq -r --arg app_name "$APP_NAME" '.applications[] | select(.name==$app_name)' > application.json
APP_ID=`cat ./application.json | jq -r '.app_id'`
CORRECT_APP_NAME=`cat ./application.json | jq -r '.name'`

if [ "$APP_ID" = "" ]; then
  echo "${APP_NAME} という名前のアプリケーションが見つかりません。"
  exit 1
fi
echo "${CORRECT_APP_NAME} -> ${APP_ID}"

echo "脆弱性"
# まずは検知した脆弱性のUUIDリストを取得
rm -f ./traces_ids.json
curl -X GET -sS \
  ${API_URL}/traces/${APP_ID}/ids \
  -H "Authorization: ${AUTHORIZATION}" \
  -H "API-Key: ${API_KEY}" \
  -H 'Accept: application/json' -J -o traces_ids.json

while read -r LINE; do
  # UUIDでまわす
  echo " - ${LINE}"
  rm -f ./trace.json
  curl -X GET -sS \
    ${API_URL}/traces/${APP_ID}/filter/${LINE}?expand=events,notes,skip_links \
    -H "Authorization: ${AUTHORIZATION}" \
    -H "API-Key: ${API_KEY}" \
    -H 'Accept: application/json' -J -o trace.json

  RULE_TITLE=`cat ./trace.json | jq -r '.trace.rule_title'`
  RULE_NAME=`cat ./trace.json | jq -r '.trace.rule_name'`
  SEVERITY=`cat ./trace.json | jq -r '.trace.severity'`
  STATUS=`cat ./trace.json | jq -r '.trace.status'`
  DESCRIPTION="${BASEURL}static/ng/index.html#/${ORG_ID}/applications/${APP_ID}/vulns/${LINE}) was found in ${CORRECT_APP_NAME}"

  jq -n \
    --arg Title "Contrast Security" \
    --arg Message "${DESCRIPTION}" \
    --arg Project "contrastsecurity4shell" \
    --arg Tracker "脆弱性" \
    --arg ApplicationName "${CORRECT_APP_NAME}" \
    --arg ApplicationCode "" \
    --arg VulnerabilityTags "" \
    --arg ApplicationId "${APP_ID}" \
    --arg ServerName "" \
    --arg ServerId "" \
    --arg OrganizationId "" \
    --arg Severity "${SEVERITY}" \
    --arg Status "${STATUS}" \
    --arg TraceId "${LINE}" \
    --arg VulnerabilityRule "${RULE_NAME}" \
    --arg Environment "" \
    --arg EventType "NEW_VULNERABILITY" \
    -f webhook.jq > ${LINE}.json
  curl -X POST -H "Content-Type: application/json" ${RM_BASEURL}contrast/vote?key=${RM_API_KEY} -d @${LINE}.json

  # コメント同期のためのトリガ
  sleep 1
  DESCRIPTION="X commented on a ${SEVERITY} vulnerability (${BASEURL}static/ng/index.html#/${ORG_ID}/applications/${APP_ID}/vulns/${LINE}) vulnerability in ${CORRECT_APP_NAME}"
  jq -n \
    --arg Title "Contrast Security" \
    --arg Message "${DESCRIPTION}" \
    --arg Project "contrastsecurity4shell" \
    --arg Tracker "脆弱性" \
    --arg ApplicationName "" \
    --arg ApplicationCode "" \
    --arg VulnerabilityTags "" \
    --arg ApplicationId "" \
    --arg ServerName "" \
    --arg ServerId "" \
    --arg OrganizationId "" \
    --arg Severity "" \
    --arg Status "" \
    --arg TraceId "" \
    --arg VulnerabilityRule "" \
    --arg Environment "" \
    --arg EventType "NEW_VULNERABILITY_COMMENT" \
    -f webhook.jq > ${LINE}_cmt.json
  curl -X POST -H "Content-Type: application/json" ${RM_BASEURL}contrast/vote?key=${RM_API_KEY} -d @${LINE}_cmt.json
done < <(cat ./traces_ids.json | jq -r '.traces[]')

# 次に検知したライブラリ脆弱性のリストを取得
echo "ライブラリ脆弱性"
rm -f ./libraries.json
curl -X GET -sS \
  ${API_URL}/applications/${APP_ID}/libraries?quickFilter=VULNERABLE \
  -H "Authorization: ${AUTHORIZATION}" \
  -H "API-Key: ${API_KEY}" \
  -H 'Accept: application/json' -J -o libraries.json

json_file=`cat ./libraries.json`
json_length=`echo ${json_file} | jq '.libraries | length'`
for i in `seq 0 $(expr ${json_length} - 1)`; do
  FILENAME=`echo ${json_file} | jq -r .libraries[${i}].file_name`
  LANGUAGE=`echo ${json_file} | jq -r .libraries[${i}].app_language | tr '[:upper:]' '[:lower:]'`
  HASH=`echo ${json_file} | jq -r .libraries[${i}].hash`
  DESCRIPTION="X was found in ${FILENAME} (${BASEURL}static/ng/index.html#/${ORG_ID}/libraries/${LANGUAGE}/${HASH}), used in ${CORRECT_APP_NAME} (${BASEURL}static/ng/index.html#/${ORG_ID}/applications/${APP_ID})."
  echo " - ${FILENAME}"
  jq -n \
    --arg Title "Contrast Security" \
    --arg Message "${DESCRIPTION}" \
    --arg Project "contrastsecurity4shell" \
    --arg Tracker "脆弱性" \
    --arg ApplicationName "${CORRECT_APP_NAME}" \
    --arg ApplicationCode "" \
    --arg VulnerabilityTags "" \
    --arg ApplicationId "${APP_ID}" \
    --arg ServerName "" \
    --arg ServerId "" \
    --arg OrganizationId "" \
    --arg Severity "" \
    --arg Status "" \
    --arg TraceId "" \
    --arg VulnerabilityRule "" \
    --arg Environment "" \
    --arg EventType "NEW_VULNERABLE_LIBRARY" \
    -f webhook.jq > ${HASH}.json
  curl -X POST -H "Content-Type: application/json" ${RM_BASEURL}contrast/vote?key=${RM_API_KEY} -d @${HASH}.json
done

rm -f *.json

exit 0

