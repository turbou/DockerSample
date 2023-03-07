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
    AUTO_VERIFICATION_TYPE=`cat ./remediation.json | jq -r --arg title "$POLICY_NAME" '.policies[] | select(.name==$title) | .auto_verification_type'`
    #echo "  application_importance: $APPLICATION_IMPORTANCE_ARRAY"
    #echo "  applications: $APPLICATIONS_ARRAY"
    #echo "  rule_severities: $RULE_SEVERITIES_ARRAY"
    #echo "  rules: $RULES_ARRAY"
    #echo "  server_environments: $SERVER_ENVIRONMENTS_ARRAY"
    curl -X POST -sS \
        ${API_URL}/policy/remediation \
        -H "Authorization: ${AUTHORIZATION}" \
        -H "API-Key: ${API_KEY}" \
        -H "Content-Type: application/json" \
        -H 'Accept: application/json' \
        -d '{"name": "'$POLICY_NAME'", "remediation_days": '$REMEDIATION_DAYS', "all_applications": '$ALL_APPLICATIONS', "application_importance": '$APPLICATION_IMPORTANCE_ARRAY', "applications": '$APPLICATIONS_ARRAY', "all_rules": '$ALL_RULES', "rule_severities": '$RULE_SEVERITIES_ARRAY', "rules": '$RULES_ARRAY', "all_server_environments": '$ALL_SERVER_ENVIRONMENTS', "server_environments": '$SERVER_ENVIRONMENTS_ARRAY', "route_based_enabled": '$ROUTE_BASED_ENABLED', "action": "'$ACTION'", "auto_verification_type": "'$AUTO_VERIFICATION_TYPE'"}'
    sleep 1
done < <(cat ./remediation.json | jq -r '.policies[].name')

exit 0

