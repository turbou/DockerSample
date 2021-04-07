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

while read -r RULE_NAME; do
    echo ""
    echo "${RULE_NAME}"
    IMPACT=`cat ./rules.json | jq -r --arg title "$RULE_NAME" '.rules[] | select(.name==$title) | .impact'`
    LIKELIHOOD=`cat ./rules.json | jq -r --arg title "$RULE_NAME" '.rules[] | select(.name==$title) | .likelihood'`
    CONFIDENCE=`cat ./rules.json | jq -r --arg title "$RULE_NAME" '.rules[] | select(.name==$title) | .confidence'`
    IMPACT_CUSTOMIZED=`cat ./rules.json | jq -r --arg title "$RULE_NAME" '.rules[] | select(.name==$title) | .customized_impact'`
    LIKELIHOOD_CUSTOMIZED=`cat ./rules.json | jq -r --arg title "$RULE_NAME" '.rules[] | select(.name==$title) | .customized_likelihood'`
    CONFIDENCE_CUSTOMIZED=`cat ./rules.json | jq -r --arg title "$RULE_NAME" '.rules[] | select(.name==$title) | .customized_confidence'`
    #echo "  impact: $IMPACT"
    #echo "  likelihood: $LIKELIHOOD"
    #echo "  confidence: $CONFIDENCE"
    #echo '{"confidence_level": "'$CONFIDENCE'", "impact": "'$IMPACT'", "likelihood": "'$LIKELIHOOD'"}' | jq > rule.json
    if [ $IMPACT_CUSTOMIZED = "false" -a $LIKELIHOOD_CUSTOMIZED = "false" -a $CONFIDENCE_CUSTOMIZED = "false" ]; then
        echo "  Skip."
        continue
    fi
    curl -X POST -sS \
        ${API_URL}/rules/${RULE_NAME} \
        -H "Authorization: ${AUTHORIZATION}" \
        -H "API-Key: ${API_KEY}" \
        -H "Content-Type: application/json" \
        -H 'Accept: application/json' \
        -d '{"confidence_level": "'$CONFIDENCE'", "impact": "'$IMPACT'", "likelihood": "'$LIKELIHOOD'"}'
    sleep 1
done < <(cat ./rules.json | jq -r '.rules[].name')

exit 0

