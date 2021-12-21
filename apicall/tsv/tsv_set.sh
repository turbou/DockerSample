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
GROUP_NAME=TempAdminGroup
ROLE_NAME=admin

# 引数処理
if [ $# != 4 ]; then
    echo ""
    echo " 例) ./tsv_set.sh -e true -r false"
    echo " 引数説明:"
    echo "   -e: 2段階認証 有効(true)/無効(false)"
    echo "   -r: 必須フラグ 必須(true)/任意(false)"
    echo ""
    exit 1
fi
ENABLED=
REQUIRED=
while getopts e:r: OPTION; do
    case $OPTION in
        e) ENABLED=$OPTARG;;
        r) REQUIRED=$OPTARG;;
    esac
done

# 既存のグループを取得します。
rm -f ./groups.json
curl -X GET -sS -G \
    ${API_URL}/superadmin/ac/groups \
    -d expand=scopes,skip_links -d q=${GROUP_NAME} -d quickFilter=CUSTOM \
    -H "Authorization: ${AUTHORIZATION}" \
    -H "API-Key: ${API_KEY}" \
    -H 'Accept: application/json' -J -o groups.json

GRP_ID=`cat ./groups.json | jq -r --arg grp_name "${GROUP_NAME}" '.groups[] | select(.name==$grp_name) | .group_id'`

# 組織一覧を取得します。
rm -f ./organizaions.json
curl -X GET -sS -G \
    ${API_URL}/superadmin/organizations \
    -d base=base -d expand=skip_links \
    -H "Authorization: ${AUTHORIZATION}" \
    -H "API-Key: ${API_KEY}" \
    -H 'Accept: application/json' -J -o organizations.json

# 組織IDからjson配列を生成します。
SCOPES=
while read -r LINE; do
    ORG_ID=`echo ${LINE} | awk -F: '{print $1}'`
    SCOPES=$SCOPES'{"org":{"id":"'$ORG_ID'","role":"'$ROLE_NAME'"},"app":{"exceptions":[]}},'
done < ./orgid_apikey_map.txt
SCOPES=`echo $SCOPES | sed "s/,$//"`
SCOPES="["$SCOPES"]"

# グループがない場合は作成、ある場合は組織の割当を更新します。
if [ "${GRP_ID}" = "" ]; then
    curl -X POST -sS \
        ${API_URL}/superadmin/ac/groups/organizational?expand=skip_links \
        -H "Authorization: ${AUTHORIZATION}" \
        -H "API-Key: ${API_KEY}" \
        -H "Content-Type: application/json" \
        -H 'Accept: application/json' \
        -d '{"name":"'$GROUP_NAME'","users":["'$USERNAME'"],"scopes":'$SCOPES'}' -J -o group_add.json
else
    curl -X PUT -sS \
        ${API_URL}/superadmin/ac/groups/organizational/${GRP_ID}?expand=skip_links \
        -H "Authorization: ${AUTHORIZATION}" \
        -H "API-Key: ${API_KEY}" \
        -H "Content-Type: application/json" \
        -H 'Accept: application/json' \
        -d '{"name":"'$GROUP_NAME'","users":["'$USERNAME'"],"scopes":'$SCOPES'}' -J -o group_upd.json
fi

# 改めてグループを取得します。
rm -f ./groups.json
curl -X GET -sS -G \
    ${API_URL}/superadmin/ac/groups \
    -d expand=scopes,skip_links -d q=${GROUP_NAME} -d quickFilter=CUSTOM \
    -H "Authorization: ${AUTHORIZATION}" \
    -H "API-Key: ${API_KEY}" \
    -H 'Accept: application/json' -J -o groups.json
GRP_ID=`cat ./groups.json | jq -r --arg grp_name "${GROUP_NAME}" '.groups[] | select(.name==$grp_name) | .group_id'`

# 組織ごとにルールの重大度を反映していきます。
while read -r LINE; do
    ORG_ID=`echo ${LINE} | awk -F: '{print $1}'`
    ORG_API_KEY=`echo ${LINE} | awk -F: '{print $2}'`
    curl -X PUT -sS \
        ${API_URL}/${ORG_ID}/tsv/organization?expand=skip_links \
        -H "Authorization: ${AUTHORIZATION}" \
        -H "API-Key: ${ORG_API_KEY}" \
        -H "Content-Type: application/json" \
        -H 'Accept: application/json' \
        -d '{"enabled":'$ENABLED',"required":'$REQUIRED'}' -J -o tsv_put.json
done < ./orgid_apikey_map.txt

# 一時的に作ったグループの削除
curl -X DELETE -sS \
    ${API_URL}/superadmin/ac/groups/${GRP_ID}?expand=skip_links \
    -H "Authorization: ${AUTHORIZATION}" \
    -H "API-Key: ${ORG_API_KEY}" \
    -H 'Accept: application/json' -J -o group_del.json

rm -f ./*.json

exit 0

