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

rm -f ./output.tsv
OFFSET=0
CURRENT_TOTAL=0
while :; do
    rm -f ./libraries.json
    curl -X POST -sS \
         "${API_URL}/libraries/filter?offset=${OFFSET}&limit=50" \
         -H "Authorization: ${AUTHORIZATION}" \
         -H "API-Key: ${API_KEY}" \
         -H "Content-Type: application/json" \
         -H 'Accept: application/json' -J -o libraries.json \
         -d '{"quickFilter":"ALL","apps":[],"servers":[],"tags":[],"languages":[],"licenses":[],"grades":[],"environments":[],"status":[],"includeUsed":false,"includeUnused":false,"q":""}'
    cat ./libraries.json | jq '.libraries | map({name: .file_name, lang: .app_language, lic: .licenses|join(",")})' | jq -r '.[] | [.name, .lic, .lang] | @tsv' >> ./output.tsv
    total=`cat ./libraries.json | jq -r .count`
    count=`cat ./libraries.json | jq -r '.libraries | length'`
    OFFSET=`expr $OFFSET + $count`
    echo "$OFFSET/$total"
    if [ $OFFSET -ge $total ]; then
        break
    fi
done

exit 0

