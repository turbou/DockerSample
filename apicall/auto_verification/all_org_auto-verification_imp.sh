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

VERSION_THRESHOLD="3.10.0"

# Contrastサーバのバージョンを取得
VERSION_310X="false"
rm -f ./properties.json
curl -X GET -sS \
     "${BASEURL}/api/ng/global/properties?expand=skip_links" \
     -H "Authorization: ${AUTHORIZATION}" \
     -H "API-Key: ${API_KEY}" \
     -H 'Accept: application/json' -J -o properties.json

CONTRAST_VERSION=`cat ./properties.json | jq -r '.internal_version'`
echo $CONTRAST_VERSION > ./version_chk.txt
echo $VERSION_THRESHOLD >> ./version_chk.txt
CHK_VERSION=`cat ./version_chk.txt | sort -t '.' -k 1,1 -k 2,2 -k 3,3 -g | tail -n 1`
if [ "$CONTRAST_VERSION" = "$CHK_VERSION" ]; then
    VERSION_310X="true"
fi

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
while read -r ORG_ID; do
    SCOPES=$SCOPES'{"org":{"id":"'$ORG_ID'","role":"rules_admin"},"app":{"exceptions":[]}},'
done < <(cat ./organizations.json | jq -r '.organizations[].organization_uuid')
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
        -d '{"name":"'$GROUP_NAME'","users":["'$USERNAME'"],"scopes":'$SCOPES'}'
else
    curl -X PUT -sS \
        ${API_URL}/superadmin/ac/groups/organizational/${GRP_ID}?expand=skip_links \
        -H "Authorization: ${AUTHORIZATION}" \
        -H "API-Key: ${API_KEY}" \
        -H "Content-Type: application/json" \
        -H 'Accept: application/json' \
        -d '{"name":"'$GROUP_NAME'","users":["'$USERNAME'"],"scopes":'$SCOPES'}'
fi

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
    echo "$ORG_ID:$GET_API_KEY" >> orgid_apikey_map.txt
done < <(cat ./organizations.json | jq -r '.organizations[].organization_uuid')

# 組織ごとに自動検証ポリシーの設定を反映していきます。
while read -r ORG_ID; do
    ORG_API_KEY=`grep ${ORG_ID} ./orgid_apikey_map.txt | awk -F: '{print $2}'`
    while read -r POLICY_NAME; do
        echo ""
        echo "${POLICY_NAME}"
        REMEDIATION_DAYS=`cat ./remediation.json | jq -r --arg title "$POLICY_NAME" '.policies[] | select(.name==$title) | .remediation_days'`
        ALL_APPLICATIONS=`cat ./remediation.json | jq -r --arg title "$POLICY_NAME" '.policies[] | select(.name==$title) | .all_applications'`
        APPLICATION_IMPORTANCE=`cat ./remediation.json | jq --arg title "$POLICY_NAME" '.policies[] | select(.name==$title) | .application_importance'`
        APPLICATION_IMPORTANCE_ARRAY=`echo $APPLICATION_IMPORTANCE | sed "s/ //g"`
        APPLICATIONS=`cat ./remediation.json | jq --arg title "$POLICY_NAME" '.policies[] | select(.name==$title) | .applications[].app_id'`
        APPLICATIONS_ARRAY=`echo $APPLICATIONS | sed "s/ /,/g" | sed "s/^/[/" | sed "s/$/]/"`
        ALL_RULES=`cat ./remediation.json | jq -r --arg title "$POLICY_NAME" '.policies[] | select(.name==$title) | .all_rules'`
        RULE_SEVERITIES=`cat ./remediation.json | jq --arg title "$POLICY_NAME" '.policies[] | select(.name==$title) | .rule_severities'`
        RULE_SEVERITIES_ARRAY=`echo $RULE_SEVERITIES | sed "s/ //g"`
        RULES=`cat ./remediation.json | jq --arg title "$POLICY_NAME" '.policies[] | select(.name==$title) | .rules[].name'`
        RULES_ARRAY=`echo $RULES | sed "s/ /,/g" | sed "s/^/[/" | sed "s/$/]/"`
        ALL_SERVER_ENVIRONMENTS=`cat ./remediation.json | jq -r --arg title "$POLICY_NAME" '.policies[] | select(.name==$title) | .all_server_environments'`
        SERVER_ENVIRONMENTS=`cat ./remediation.json | jq --arg title "$POLICY_NAME" '.policies[] | select(.name==$title) | .server_environments[].value'`
        SERVER_ENVIRONMENTS_ARRAY=`echo $SERVER_ENVIRONMENTS | sed "s/ /,/g" | sed "s/^/[/" | sed "s/$/]/"`
        ROUTE_BASED_ENABLED=`cat ./remediation.json | jq -r --arg title "$POLICY_NAME" '.policies[] | select(.name==$title) | .route_based_enabled'`
        ACTION=`cat ./remediation.json | jq -r --arg title "$POLICY_NAME" '.policies[] | select(.name==$title) | .action'`
        if [ "$VERSION_310X" = "true" ]; then
            AUTO_VERIFICATION_TYPE=`cat ./remediation.json | jq -r --arg title "$POLICY_NAME" '.policies[] | select(.name==$title) | .auto_verification_type'`
        fi
        #echo "  application_importance: $APPLICATION_IMPORTANCE_ARRAY"
        #echo "  applications: $APPLICATIONS_ARRAY"
        #echo "  rule_severities: $RULE_SEVERITIES_ARRAY"
        #echo "  rules: $RULES_ARRAY"
        #echo "  server_environments: $SERVER_ENVIRONMENTS_ARRAY"
        if [ "$VERSION_310X" = "true" ]; then
            curl -X POST -sS \
                ${API_URL}/${ORG_ID}/policy/remediation \
                -H "Authorization: ${AUTHORIZATION}" \
                -H "API-Key: ${ORG_API_KEY}" \
                -H "Content-Type: application/json" \
                -H 'Accept: application/json' \
                -d '{"name": "'$POLICY_NAME'", "remediation_days": '$REMEDIATION_DAYS', "all_applications": '$ALL_APPLICATIONS', "application_importance": '$APPLICATION_IMPORTANCE_ARRAY', "applications": '$APPLICATIONS_ARRAY', "all_rules": '$ALL_RULES', "rule_severities": '$RULE_SEVERITIES_ARRAY', "rules": '$RULES_ARRAY', "all_server_environments": '$ALL_SERVER_ENVIRONMENTS', "server_environments": '$SERVER_ENVIRONMENTS_ARRAY', "route_based_enabled": '$ROUTE_BASED_ENABLED', "action": "'$ACTION'", "auto_verification_type": "'$AUTO_VERIFICATION_TYPE'"}'
        else
            curl -X POST -sS \
                ${API_URL}/${ORG_ID}/policy/remediation \
                -H "Authorization: ${AUTHORIZATION}" \
                -H "API-Key: ${ORG_API_KEY}" \
                -H "Content-Type: application/json" \
                -H 'Accept: application/json' \
                -d '{"name": "'$POLICY_NAME'", "remediation_days": '$REMEDIATION_DAYS', "all_applications": '$ALL_APPLICATIONS', "application_importance": '$APPLICATION_IMPORTANCE_ARRAY', "applications": '$APPLICATIONS_ARRAY', "all_rules": '$ALL_RULES', "rule_severities": '$RULE_SEVERITIES_ARRAY', "rules": '$RULES_ARRAY', "all_server_environments": '$ALL_SERVER_ENVIRONMENTS', "server_environments": '$SERVER_ENVIRONMENTS_ARRAY', "route_based_enabled": '$ROUTE_BASED_ENABLED', "action": "'$ACTION'"}'
        fi
        sleep 1
    done < <(cat ./remediation.json | jq -r '.policies[].name')
done < <(cat ./organizations.json | jq -r '.organizations[].organization_uuid')

exit 0

