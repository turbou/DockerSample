#!/bin/bash

if [ -z "$CONTRAST_BASEURL" -o -z "$CONTRAST_API_KEY" -o -z "$CONTRAST_USERNAME" -o -z "$CONTRAST_SERVICE_KEY" -o -z "$CONTRAST_ORG_ID" -o -z "$CONTRAST_APP_ID" ]; then
    echo '環境変数が設定されていません。'
    echo 'CONTRAST_BASEURL       : https://(app|eval).contrastsecurity.com/Contrast'
    echo 'CONTRAST_USERNAME      : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
    echo 'CONTRAST_SERVICE_KEY   : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
    echo 'CONTRAST_ORG_ID        : XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'
    echo 'CONTRAST_API_KEY       : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
    echo 'CONTRAST_APP_ID        : XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'
    exit 1
fi

BASEURL=$CONTRAST_BASEURL
API_KEY=$CONTRAST_API_KEY
USERNAME=$CONTRAST_USERNAME
SERVICE_KEY=$CONTRAST_SERVICE_KEY
AUTHORIZATION=`echo "$(echo -n $USERNAME:$SERVICE_KEY | base64)"`
ORG_ID=$CONTRAST_ORG_ID
APP_ID=$CONTRAST_APP_ID
API_URL="${BASEURL}/api/ng"

rm -f ./organization.json
curl -X GET -sS \
     ${API_URL}/profile/organizations/${ORG_ID}?expand=freemium,skip_links \
     -H "Authorization: ${AUTHORIZATION}" \
     -H "API-Key: ${API_KEY}" \
     -H 'Accept: application/json' -J -o organization.json

ORG_NAME=`cat ./organization.json | jq -r '.organization.name'`
if [ -z $ORG_NAME ]; then
    echo ""
    echo "  APIの実行に失敗しました。環境変数の値が正しいか、ご確認ください。"
    echo ""
    exit 1
fi
echo ""
echo "  対象組織: $ORG_NAME"
echo ""
rm -f ./organization.json

rm -f ./rules.json
curl -X GET -sS \
     ${API_URL}/${ORG_ID}/assess/rules/configs/app/${APP_ID} \
     -d expand=skip_links \
     -H "Authorization: ${AUTHORIZATION}" \
     -H "API-Key: ${API_KEY}" \
     -H 'Accept: application/json' -J -o rules.json

exit 0

