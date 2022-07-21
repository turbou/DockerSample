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

usage() {
  cat <<EOF
  Usage: $0 [options]
  -m|--mode on/off
EOF
}

MODE=
while getopts m-: opt; do
  optarg="${!OPTIND}"
  [[ "$opt" = - ]] && opt="-$OPTARG"
  case "-$opt" in
    -m|--mode)
      MODE="$optarg"
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

if [ "$MODE" = "on" ]; then
    MODE="true"
elif [ "$MODE" = "off" ]; then
    MODE="false"
else
    usage
    exit 1
fi

rm -f ./rules.json
curl -X GET -sS \
     ${API_URL}/rules \
     -H "Authorization: ${AUTHORIZATION}" \
     -H "API-Key: ${API_KEY}" \
     -H 'Accept: application/json' -J -o rules.json

RULES=
while read -r RULE_NAME; do
    RULES="$RULES $RULE_NAME"
done < <(cat ./rules.json | jq -r '.rules[].name')

DATA=`jq --arg mode "${MODE}" -nc '{rule_names:$ARGS.positional,"dev_enabled":$mode,"qa_enabled":$mode,"prod_enabled":$mode}' --args $RULES`

rm -f ./applications.json
curl -X GET -sS \
     ${API_URL}/applications?expand=skip_links \
     -H "Authorization: ${AUTHORIZATION}" \
     -H "API-Key: ${API_KEY}" \
     -H 'Accept: application/json' -J -o applications.json

while read -r APP_ID; do
    echo ""
    APP_NAME=`cat ./applications.json | jq -r --arg app_id "$APP_ID" '.applications[] | select(.app_id==$app_id) | .name'`
    echo "${APP_ID} - ${APP_NAME}"
    curl -X PUT -sS \
        ${API_URL}/assess/rules/configs/app/${APP_ID}/bulk?expand=skip_links \
        -H "Authorization: ${AUTHORIZATION}" \
        -H "API-Key: ${API_KEY}" \
        -H "Content-Type: application/json" \
        -H 'Accept: application/json' \
        -d "${DATA}"
    sleep 1
done < <(cat ./applications.json | jq -r '.applications[].app_id')

exit 0

