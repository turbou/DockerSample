#!/bin/bash

if [ -z "$CONTRAST_BASEURL" -o -z "$CONTRAST_AUTHORIZATION" -o -z "$CONTRAST_API_KEY" -o -z "$CONTRAST_ORG_ID" -o -z "$CONTRAST_APP_NAME" ]; then
    echo '環境変数が設定されていません。'
    echo 'CONTRAST_BASEURL       : https://(app|eval).contrastsecurity.com/Contrast/'
    echo 'CONTRAST_AUTHORIZATION : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX=='
    echo 'CONTRAST_API_KEY       : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
    echo 'CONTRAST_ORG_ID        : XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'
    echo 'CONTRAST_APP_NAME      : PetClinic_8001'
    exit 1
fi

BASEURL=$CONTRAST_BASEURL
API_KEY=$CONTRAST_API_KEY
AUTHORIZATION=$CONTRAST_AUTHORIZATION
ORG_ID=$CONTRAST_ORG_ID
API_URL="${BASEURL}api/ng/${ORG_ID}"
APP_NAME=$CONTRAST_APP_NAME

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

APP_ID=""
while read -r LINE; do
    APP_ID="${LINE}"
done < <(cat ./applications.json | jq -r --arg app_name "$APP_NAME" '.applications[] | select(.name==$app_name) | .app_id')

if [ "$APP_ID" = "" ]; then
    echo "${APP_NAME} という名前のアプリケーションが見つかりません。"
    exit 1
fi
echo "${APP_NAME} -> ${APP_ID}"

# まずは検知した脆弱性のUUIDリストを取得
rm -f ./traces_ids.json
curl -X GET -sS \
     ${API_URL}/traces/${APP_ID}/ids?appVersionTags=${APP_VERSION} \
     -H "Authorization: ${AUTHORIZATION}" \
     -H "API-Key: ${API_KEY}" \
     -H 'Accept: application/json' -J -o traces_ids.json

while read -r LINE; do
    # UUIDでまわす
    echo "- ${LINE} -----------------------------------"
    rm -f ./trace.json
    curl -X GET -sS \
         ${API_URL}/traces/${APP_ID}/filter/${LINE}?expand=events,notes,skip_links \
         -H "Authorization: ${AUTHORIZATION}" \
         -H "API-Key: ${API_KEY}" \
         -H 'Accept: application/json' -J -o trace.json

    # 脆弱性基本情報
    FIRST_TIME_SEEN_UNIX_TIME=`cat ./trace.json | jq -r '.trace.first_time_seen'`
    FIRST_TIME_SEEN_UNIX_TIME=`echo ${FIRST_TIME_SEEN_UNIX_TIME} | cut -c 1-10`
    FIRST_TIME_SEEN=`date -d @${FIRST_TIME_SEEN_UNIX_TIME} +"%Y/%m/%d %H:%M"`
    RULE_TITLE=`cat ./trace.json | jq -r '.trace.rule_title'`
    SEVERITY=`cat ./trace.json | jq -r '.trace.severity'`
    STATUS=`cat ./trace.json | jq -r '.trace.status'`
    echo "脆弱性タイトル: ${RULE_TITLE}"
    echo "重大度        : ${SEVERITY}"
    echo "ステータス    : ${STATUS}"
    echo "検出日時      : ${FIRST_TIME_SEEN}"

    # Overview
    rm -f ./story.json
    curl -X GET -sS \
         ${API_URL}/traces/${LINE}/story?expand=skip_links \
         -H "Authorization: ${AUTHORIZATION}" \
         -H "API-Key: ${API_KEY}" \
         -H 'Accept: application/json' -J -o story.json
    RISK=`cat ./story.json | jq -r '.story.risk.text'`
    echo "概要          :"
    echo ${RISK}

    # How to Fix
    rm -f ./howtofix.json
    curl -X GET -sS \
         ${API_URL}/traces/${LINE}/recommendation?expand=skip_links \
         -H "Authorization: ${AUTHORIZATION}" \
         -H "API-Key: ${API_KEY}" \
         -H 'Accept: application/json' -J -o howtofix.json
    HOWTOFIX=`cat ./howtofix.json | jq -r '.recommendation.text'`
    echo "How to Fix    :"
    echo ${HOWTOFIX}

    # CWE
    CWE=`cat ./howtofix.json | jq -r '.cwe'`
    echo "CWE           : ${CWE}"

    # OWASP
    OWASP=`cat ./howtofix.json | jq -r '.owasp'`
    echo "OWASP         : ${OWASP}"

    # コメント履歴
    NOTE_LENGTH=`cat ./trace.json | jq -r '.trace.notes | length'`
    if [ $NOTE_LENGTH -gt 0 ]; then
        echo "コメント      :"
        while read -r LINE2; do
            CREATION_UNIX_TIME=`cat ./trace.json | jq -r --arg note_id "$LINE2" '.trace.notes[] | select(.id==$note_id) | .creation'`
            CREATION_UNIX_TIME=`echo ${CREATION_UNIX_TIME} | cut -c 1-10`
            CREATION=`date -d @${CREATION_UNIX_TIME} +"%Y/%m/%d %H:%M"`
            CREATOR=`cat ./trace.json | jq -r --arg note_id "$LINE2" '.trace.notes[] | select(.id==$note_id) | .creator'`
            NOTE_HTML=`cat ./trace.json | jq -r --arg note_id "$LINE2" '.trace.notes[] | select(.id==$note_id) | .note'`
            NOTE=`echo ${NOTE_HTML} | recode html..utf8`
            echo "${CREATION} - ${CREATOR}"
            echo "${NOTE}"
        done < <(cat ./trace.json | jq -r '.trace.notes[] | .id')
    fi
done < <(cat ./traces_ids.json | jq -r '.traces[]')

exit 0

