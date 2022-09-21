#!/bin/bash

if [ -z "$CONTRAST_BASEURL" -o -z "$CONTRAST_API_KEY" -o -z "$CONTRAST_USERNAME" -o -z "$CONTRAST_SERVICE_KEY" -o -z "$CONTRAST_ORG_ID" ]; then
    echo '環境変数が設定されていません。'
    echo 'CONTRAST_BASEURL       : https://(app|eval).contrastsecurity.com/Contrast'
    echo 'CONTRAST_USERNAME      : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
    echo 'CONTRAST_SERVICE_KEY   : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
    echo 'CONTRAST_ORG_ID        : XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'
    echo 'CONTRAST_API_KEY       : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
    exit 1
fi

BASEURL=$CONTRAST_BASEURL
API_KEY=$CONTRAST_API_KEY
USERNAME=$CONTRAST_USERNAME
SERVICE_KEY=$CONTRAST_SERVICE_KEY
AUTHORIZATION=`echo "$(echo -n $USERNAME:$SERVICE_KEY | base64)"`
ORG_ID=$CONTRAST_ORG_ID
API_URL="${BASEURL}/api/ng"

usage() {
  cat <<EOF
  Usage: $0 [options]
  -t|--target all|org|app
EOF
}

TARGET=
while getopts t-: opt; do
  optarg="${!OPTIND}"
  [[ "$opt" = - ]] && opt="-$OPTARG"
  case "-$opt" in
    -t|--target)
      TARGET="$optarg"
      shift
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

if [ "${TARGET}" = "all" ]; then
    TARGET="ALL"
elif [ "${TARGET}" = "org" ]; then
    TARGET="ORG"
elif [ "${TARGET}" = "app" ]; then
    TARGET="APP"
else
    usage
    exit 1
fi

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

rm -f ./configs_org.csv
rm -f ./configs_app.csv
while read -r RULE_NAME; do
    DEV_FLG=`cat ./rules.json | jq -r --arg rule_name "$RULE_NAME" '.configs[] | select(.rule_name==$rule_name) | .dev_enabled'`
    QA_FLG=`cat ./rules.json | jq -r --arg rule_name "$RULE_NAME" '.configs[] | select(.rule_name==$rule_name) | .qa_enabled'`
    PROD_FLG=`cat ./rules.json | jq -r --arg rule_name "$RULE_NAME" '.configs[] | select(.rule_name==$rule_name) | .prod_enabled'`
    echo "${RULE_NAME},${DEV_FLG},DEVELOPMENT" >> ./configs_org.csv
    echo "${RULE_NAME},${QA_FLG},QA" >> ./configs_org.csv
    echo "${RULE_NAME},${PROD_FLG},PRODUCTION" >> ./configs_org.csv
    echo "${RULE_NAME},${DEV_FLG},${QA_FLG},${PROD_FLG}" >> ./configs_app.csv
done < <(cat ./rules.json | jq -r '.configs[].name')

if [ "${TARGET}" = "ALL" -o "${TARGET}" = "ORG" ]; then
    while read -r LINE; do
        NAME=`echo $LINE | awk -F, '{print $1}'`
        FLG=`echo $LINE | awk -F, '{print $2}'`
        ENVIRONMENT=`echo $LINE | awk -F, '{print $3}'`
        DATA=`jq --argjson flg "${FLG}" --arg environment "${ENVIRONMENT}" -nc '{"enabled":$flg,"environment":$environment}'`
        echo ""
        echo "$NAME $DATA"
        curl -X PUT -sS \
            ${API_URL}/${ORG_ID}/rules/${NAME}/status?expand=skip_links \
            -H "Authorization: ${AUTHORIZATION}" \
            -H "API-Key: ${API_KEY}" \
            -H "Content-Type: application/json" \
            -H 'Accept: application/json' \
            -d "${DATA}"
        sleep 1
    done < ./configs_org.csv
fi

if [ "${TARGET}" = "ALL" -o "${TARGET}" = "APP" ]; then
    rm -f ./applications.json
    curl -X GET -sS \
         ${API_URL}/${ORG_ID}/applications?expand=skip_links \
         -H "Authorization: ${AUTHORIZATION}" \
         -H "API-Key: ${API_KEY}" \
         -H 'Accept: application/json' -J -o applications.json

    while read -r APP_ID; do
        echo ""
        APP_NAME=`cat ./applications.json | jq -r --arg app_id "$APP_ID" '.applications[] | select(.app_id==$app_id) | .name'`
        echo "${APP_ID} - ${APP_NAME}"
        while read -r LINE; do
            NAME=`echo $LINE | awk -F, '{print $1}'`
            DEV=`echo $LINE | awk -F, '{print $2}'`
            QA=`echo $LINE | awk -F, '{print $3}'`
            PROD=`echo $LINE | awk -F, '{print $4}'`
            DATA=`jq --arg name "${NAME}" --argjson dev "${DEV}" --argjson qa "${QA}" --argjson prod "${PROD}" -nc '{rule_names:[$name],"dev_enabled":$dev,"qa_enabled":$qa,"prod_enabled":$prod}'`
            echo ""
            echo "$NAME $DATA"
            curl -X PUT -sS \
                ${API_URL}/${ORG_ID}/assess/rules/configs/app/${APP_ID}/bulk?expand=skip_links \
                -H "Authorization: ${AUTHORIZATION}" \
                -H "API-Key: ${API_KEY}" \
                -H "Content-Type: application/json" \
                -H 'Accept: application/json' \
                -d "${DATA}"
            sleep 1
        done < ./configs_app.csv
        sleep 1
    done < <(cat ./applications.json | jq -r '.applications[].app_id')
fi

exit 0

