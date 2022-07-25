#!/bin/bash

if [ -z "$CONTRAST_BASEURL" -o -z "$CONTRAST_API_KEY" -o -z "$CONTRAST_USERNAME" -o -z "$CONTRAST_SERVICE_KEY" -o -z "$CONTRAST_ORG_ID" ]; then
    echo '環境変数が設定されていません。'
    echo 'CONTRAST_BASEURL       : https://(app|eval).contrastsecurity.com/Contrast'
    echo 'CONTRAST_API_KEY       : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
    echo 'CONTRAST_USERNAME      : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
    echo 'CONTRAST_SERVICE_KEY   : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
    echo 'CONTRAST_ORG_ID        : XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'
    exit 1
fi

BASEURL=$CONTRAST_BASEURL
API_KEY=$CONTRAST_API_KEY
USERNAME=$CONTRAST_USERNAME
SERVICE_KEY=$CONTRAST_SERVICE_KEY
AUTHORIZATION=`echo "$(echo -n $USERNAME:$SERVICE_KEY | base64)"`
ORG_ID=$CONTRAST_ORG_ID
API_URL="${BASEURL}/api/ng/${ORG_ID}"

rm -f ./applications.json
curl -X GET -sS \
     ${API_URL}/applications?expand=skip_links \
     -H "Authorization: ${AUTHORIZATION}" \
     -H "API-Key: ${API_KEY}" \
     -H 'Accept: application/json' -J -o applications.json

rm -f ./configs.csv
while read -r RULE_NAME; do
    DEV_FLG=`cat ./rules.json | jq -r --arg rule_name "$RULE_NAME" '.configs[] | select(.rule_name==$rule_name) | .dev_enabled'`
    QA_FLG=`cat ./rules.json | jq -r --arg rule_name "$RULE_NAME" '.configs[] | select(.rule_name==$rule_name) | .qa_enabled'`
    PROD_FLG=`cat ./rules.json | jq -r --arg rule_name "$RULE_NAME" '.configs[] | select(.rule_name==$rule_name) | .prod_enabled'`
    echo "${RULE_NAME},${DEV_FLG},${QA_FLG},${PROD_FLG}" >> ./configs.csv
done < <(cat ./rules.json | jq -r '.configs[].rule_name')

while read -r APP_ID; do
    echo ""
    APP_NAME=`cat ./applications.json | jq -r --arg app_id "$APP_ID" '.applications[] | select(.app_id==$app_id) | .name'`
    echo "${APP_ID} - ${APP_NAME}"
    while read -r LINE; do
        NAME=`echo $LINE | awk -F, '{print $1}'`
        DEV=`echo $LINE | awk -F, '{print $2}'`
        QA=`echo $LINE | awk -F, '{print $3}'`
        PROD=`echo $LINE | awk -F, '{print $4}'`
        DATA=`jq --arg name "${NAME}" --arg dev "${DEV}" --arg qa "${QA}" --arg prod "${PROD}" -nc '{rule_names:[$name],"dev_enabled":$dev,"qa_enabled":$qa,"prod_enabled":$prod}'`
        echo $DATA
        curl -X PUT -sS \
            ${API_URL}/assess/rules/configs/app/${APP_ID}/bulk?expand=skip_links \
            -H "Authorization: ${AUTHORIZATION}" \
            -H "API-Key: ${API_KEY}" \
            -H "Content-Type: application/json" \
            -H 'Accept: application/json' \
            -d "${DATA}"
        sleep 1
    done < ./configs.csv
    sleep 1
done < <(cat ./applications.json | jq -r '.applications[].app_id')

exit 0

