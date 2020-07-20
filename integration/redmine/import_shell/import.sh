#!/bin/sh

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

exit 0

