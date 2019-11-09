#!/bin/sh

CONTRAST_URL="https://xxx.contrastsecurity.com/Contrast"
AUTH_HEADER="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
API_KEY="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

ORG_ID="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
APP_ID="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"

echo "RESET APPLICATION"
curl -X PUT -sS \
     ${CONTRAST_URL}/api/ng/${ORG_ID}/applications/${APP_ID}/reset?expand=skip_links \
     -H "Authorization: ${AUTH_HEADER}" \
     -H "API-Key: ${API_KEY}" \
     -H "Accept: application/json"

echo ""
echo "SUPPRESS ATTACKS"
rm -f ./attacks.json
curl -X GET -sS \
     ${CONTRAST_URL}/api/ng/${ORG_ID}/attacks?applications=${APP_ID} \
     -H "Authorization: ${AUTH_HEADER}" \
     -H "API-Key: ${API_KEY}" \
     -H 'Accept: application/json' -J -o attacks.json

printf "attack count: %d\n" `cat ./attacks.json | jq -r '.count'`

cat ./attacks.json | jq -r '.attacks[].uuid' | while read LINE; do
  curl -X PUT -sS \
     ${CONTRAST_URL}/api/ng/${ORG_ID}/attacks/${LINE}/suppress?expand=skip_links \
     -H "Authorization: ${AUTH_HEADER}" \
     -H "API-Key: ${API_KEY}" \
     -H 'Accept: application/json'
done

exit 0

