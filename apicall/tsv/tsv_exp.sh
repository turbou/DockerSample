#!/bin/bash

if [ -z "$CONTRAST_BASEURL" -o -z "$CONTRAST_API_KEY" -o -z "$CONTRAST_USERNAME" -o -z "$CONTRAST_SERVICE_KEY" ]; then
    echo '環境変数が設定されていません。'
    echo 'CONTRAST_BASEURL       : https://(app|eval).contrastsecurity.com/Contrast'
    echo 'CONTRAST_API_KEY       : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
    echo 'CONTRAST_USERNAME      : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
    echo 'CONTRAST_SERVICE_KEY   : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
    echo '!!注意!! USERNAME, SERVICE_KEYはSuperAdmin権限を持つユーザーとしてください。'
    exit 1
fi

BASEURL=$CONTRAST_BASEURL
API_KEY=$CONTRAST_API_KEY
USERNAME=$CONTRAST_USERNAME       # SuperAdminユーザー
SERVICE_KEY=$CONTRAST_SERVICE_KEY # SuperAdminユーザー
AUTHORIZATION=`echo "$(echo -n $USERNAME:$SERVICE_KEY | base64)"`
API_URL="${BASEURL}/api/ng"
GROUP_NAME=RulesAdminGroup

# 組織一覧を取得します。
rm -f ./organizaions.json
curl -X GET -sS -G \
    ${API_URL}/superadmin/organizations \
    -d base=base -d expand=skip_links \
    -H "Authorization: ${AUTHORIZATION}" \
    -H "API-Key: ${API_KEY}" \
    -H 'Accept: application/json' -J -o organizations.json

# 組織ごとのAPIキーを取得します。
rm -f orgid_apikey_map.txt
while read -r ORG_ID; do
    curl -X GET -sS -G \
        ${API_URL}/superadmin/users/${ORG_ID}/keys/apikey?expand=skip_links \
        -d base=base -d expand=skip_links \
        -H "Authorization: ${AUTHORIZATION}" \
        -H "API-Key: ${API_KEY}" \
        -H 'Accept: application/json' -J -o apikey.json
    GET_API_KEY=`cat ./apikey.json | jq -r '.api_key'`
    GET_ORG_NAME=`cat ./organizations.json | jq -r --arg org_id $ORG_ID '.organizations[] | select(.organization_uuid == $org_id).name'`
    echo "$ORG_ID:$GET_API_KEY:$GET_ORG_NAME" >> orgid_apikey_map.txt
done < <(cat ./organizations.json | jq -r '.organizations[].organization_uuid')

# 組織ごとの２段階認証の状態を取得します。
rm -f tsv.txt
while read -r ORG_ID; do
    ORG_API_KEY=`grep ${ORG_ID} ./orgid_apikey_map.txt | awk -F: '{print $2}'`
    ORG_NAME=`grep ${ORG_ID} ./orgid_apikey_map.txt | awk -F: '{print $3}'`
    curl -X GET -sS -G \
        ${API_URL}/${ORG_ID}/tsv/organization?expand=skip_links \
        -d base=base -d expand=skip_links \
        -H "Authorization: ${AUTHORIZATION}" \
        -H "API-Key: ${ORG_API_KEY}" \
        -H 'Accept: application/json' -J -o tsv.json
    SUCCESS=`cat ./tsv.json | jq -r '.success'`
    TSV_ENABLED=`cat ./tsv.json | jq -r '.tsv.enabled'`
    TSV_REQUIRED=`cat ./tsv.json | jq -r '.tsv.required'`
    echo "$ORG_NAME" >> tsv.txt
    echo "  2段階認証: $TSV_ENABLED" >> tsv.txt
    echo "  使用必須: $TSV_REQUIRED" >> tsv.txt
done < <(cat ./organizations.json | jq -r '.organizations[].organization_uuid')

rm -f ./*.json

exit 0

