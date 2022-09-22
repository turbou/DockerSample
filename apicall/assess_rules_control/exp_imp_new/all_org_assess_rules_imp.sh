#!/bin/bash

if [ -z "$CONTRAST_BASEURL" -o -z "$CONTRAST_API_KEY" -o -z "$CONTRAST_USERNAME" -o -z "$CONTRAST_SERVICE_KEY" ]; then
    echo '環境変数が設定されていません。'
    echo 'CONTRAST_BASEURL       : https://(app|eval).contrastsecurity.com/Contrast'
    echo 'CONTRAST_USERNAME      : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
    echo 'CONTRAST_SERVICE_KEY   : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
    echo 'CONTRAST_API_KEY       : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
    echo '!!注意!! USERNAME, SERVICE_KEYはSuperAdmin権限を持つユーザーとしてください。'
    exit 1
fi

BASEURL=$CONTRAST_BASEURL
API_KEY=$CONTRAST_API_KEY
USERNAME=$CONTRAST_USERNAME       # SuperAdminユーザー
SERVICE_KEY=$CONTRAST_SERVICE_KEY # SuperAdminユーザー
AUTHORIZATION=`echo "$(echo -n $USERNAME:$SERVICE_KEY | base64)"`
API_URL="${BASEURL}/api/ng"
GROUP_NAME=HgSTXED7kZdZu92b
ORGS_LIMIT=10
GRPS_LIMIT=10

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

rm -f ./organizations.json
curl -X GET -sS \
     ${API_URL}/superadmin/organizations?limit=${ORGS_LIMIT}\&offset=0 \
     -H "Authorization: ${AUTHORIZATION}" \
     -H "API-Key: ${API_KEY}" \
     -H 'Accept: application/json' -J -o organizations.json

ORG_CNT=`cat ./organizations.json | jq -r '.count'`
if [ -z $ORG_CNT ]; then
    echo ""
    echo "  APIの実行に失敗しました。環境変数の値が正しいか、ご確認ください。"
    echo ""
    exit 1
fi
echo ""
echo "  対象組織数: $ORG_CNT"
echo ""
rm -f ./organizations.json

# 既存のグループを取得します。
rm -f ./groups.json
rm -f ./grp_names.txt
curl -X GET -sS -G \
     ${API_URL}/superadmin/ac/groups \
     -d expand=scopes,skip_links -d quickFilter=CUSTOM -d limit=${GRPS_LIMIT} -d offset=0 \
     -H "Authorization: ${AUTHORIZATION}" \
     -H "API-Key: ${API_KEY}" \
     -H 'Accept: application/json' -J -o groups.json
while read -r GRP_NAME; do
    echo $GRP_NAME >> ./grp_names.txt
done < <(cat ./groups.json | jq -r '.groups[].name')
GRP_CNT=`cat ./groups.json | jq -r '.count'`
CURRENT_GRP_CNT=`wc -l ./grp_names.txt | awk '{print $1}'`
while [ $GRP_CNT -gt $CURRENT_GRP_CNT ]
do
    curl -X GET -sS -G \
         ${API_URL}/superadmin/ac/groups \
         -d expand=scopes,skip_links -d quickFilter=CUSTOM -d limit=${GRPS_LIMIT} -d offset=$CURRENT_GRP_CNT \
         -H "Authorization: ${AUTHORIZATION}" \
         -H "API-Key: ${API_KEY}" \
         -H 'Accept: application/json' -J -o groups.json
    while read -r GRP_NAME; do
        echo $GRP_NAME >> ./grp_names.txt
    done < <(cat ./groups.json | jq -r '.groups[].name')
    CURRENT_GRP_CNT=`wc -l ./grp_names.txt | awk '{print $1}'`
done

grep ${GROUP_NAME} ./grp_names.txt > /dev/null
GRP_FOUND=$?

# 組織一覧を取得します。
rm -f ./organizaions.json
rm -f ./org_ids.txt
curl -X GET -sS -G \
     ${API_URL}/superadmin/organizations?limit=${ORGS_LIMIT}\&offset=0 \
     -d base=base -d expand=skip_links \
     -H "Authorization: ${AUTHORIZATION}" \
     -H "API-Key: ${API_KEY}" \
     -H 'Accept: application/json' -J -o organizations.json
while read -r ORG_ID; do
    LOCKED=`cat ./organizations.json | jq -r --arg org_id "${ORG_ID}" '.organizations[] | select(.organization_uuid==$org_id) | .locked'`
    NAME=`cat ./organizations.json | jq -r --arg org_id "${ORG_ID}" '.organizations[] | select(.organization_uuid==$org_id) | .name'`
    if [ "${LOCKED}" = "true" ]; then
        ORG_CNT=`expr $ORG_CNT - 1`
    else
        echo $ORG_ID >> ./org_ids.txt
    fi 
done < <(cat ./organizations.json | jq -r '.organizations[].organization_uuid')
CURRENT_ORG_CNT=`wc -l ./org_ids.txt | awk '{print $1}'`
while [ $ORG_CNT -gt $CURRENT_ORG_CNT ]
do
    curl -X GET -sS -G \
         ${API_URL}/superadmin/organizations?limit=${ORGS_LIMIT}\&offset=$CURRENT_ORG_CNT \
         -d base=base -d expand=skip_links \
         -H "Authorization: ${AUTHORIZATION}" \
         -H "API-Key: ${API_KEY}" \
         -H 'Accept: application/json' -J -o organizations.json
    while read -r ORG_ID; do
        LOCKED=`cat ./organizations.json | jq -r --arg org_id "${ORG_ID}" '.organizations[] | select(.organization_uuid==$org_id) | .locked'`
        NAME=`cat ./organizations.json | jq -r --arg org_id "${ORG_ID}" '.organizations[] | select(.organization_uuid==$org_id) | .name'`
        if [ "${LOCKED}" = "true" ]; then
            ORG_CNT=`expr $ORG_CNT - 1`
        else
            echo $ORG_ID >> ./org_ids.txt
        fi
    done < <(cat ./organizations.json | jq -r '.organizations[].organization_uuid')
    CURRENT_ORG_CNT=`wc -l ./org_ids.txt | awk '{print $1}'`
done

# 組織IDからjson配列を生成します。
SCOPES=
while read -r ORG_ID; do
    SCOPES=$SCOPES'{"org":{"id":"'$ORG_ID'","role":"rules_admin"},"app":{"exceptions":[],"role":"rules_admin"}},'
done < <(cat ./org_ids.txt)
SCOPES=`echo $SCOPES | sed "s/,$//"`
SCOPES="["$SCOPES"]"

# グループがない場合は作成します。
if [ $GRP_FOUND -ne 0 ]; then
    curl -X POST -sS \
        ${API_URL}/superadmin/ac/groups/organizational?expand=skip_links \
        -H "Authorization: ${AUTHORIZATION}" \
        -H "API-Key: ${API_KEY}" \
        -H "Content-Type: application/json" \
        -H 'Accept: application/json' \
        -d '{"name":"'$GROUP_NAME'","users":["'$USERNAME'"],"scopes":'$SCOPES'}'
else
    echo "既にグループが存在しています。"
    exit 1
fi

rm -f ./groups.json
rm -f ./grp_idnames.txt
curl -X GET -sS -G \
     ${API_URL}/superadmin/ac/groups \
     -d expand=scopes,skip_links -d quickFilter=CUSTOM -d limit=${GRPS_LIMIT} -d offset=0 \
     -H "Authorization: ${AUTHORIZATION}" \
     -H "API-Key: ${API_KEY}" \
     -H 'Accept: application/json' -J -o groups.json
while read -r GRP_NAME; do
    GRP_ID=`cat ./groups.json | jq -r --arg grp_name "${GRP_NAME}" '.groups[] | select(.name==$grp_name) | .group_id'`
    echo "$GRP_NAME,$GRP_ID" >> ./grp_idnames.txt
done < <(cat ./groups.json | jq -r '.groups[].name')
GRP_CNT=`cat ./groups.json | jq -r '.count'`
CURRENT_GRP_CNT=`wc -l ./grp_idnames.txt | awk '{print $1}'`
while [ $GRP_CNT -gt $CURRENT_GRP_CNT ]
do
    curl -X GET -sS -G \
         ${API_URL}/superadmin/ac/groups \
         -d expand=scopes,skip_links -d quickFilter=CUSTOM -d limit=${GRPS_LIMIT} -d offset=$CURRENT_GRP_CNT \
         -H "Authorization: ${AUTHORIZATION}" \
         -H "API-Key: ${API_KEY}" \
         -H 'Accept: application/json' -J -o groups.json
    while read -r GRP_NAME; do
        GRP_ID=`cat ./groups.json | jq -r --arg grp_name "${GRP_NAME}" '.groups[] | select(.name==$grp_name) | .group_id'`
        echo "$GRP_NAME,$GRP_ID" >> ./grp_idnames.txt
    done < <(cat ./groups.json | jq -r '.groups[].name')
    CURRENT_GRP_CNT=`wc -l ./grp_idnames.txt | awk '{print $1}'`
done
GRP_ID=`grep ${GROUP_NAME} ./grp_idnames.txt /dev/null | awk -F, '{print $2}'`

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
done < <(cat ./org_ids.txt)

rm -f ./configs_org.csv
rm -f ./configs_app.csv
while read -r RULE_NAME; do
    DEV_FLG=`cat ./rules.json | jq -r --arg rule_name "$RULE_NAME" '.rules[] | select(.name==$rule_name) | .enabled_dev'`
    QA_FLG=`cat ./rules.json | jq -r --arg rule_name "$RULE_NAME" '.rules[] | select(.name==$rule_name) | .enabled_qa'`
    PROD_FLG=`cat ./rules.json | jq -r --arg rule_name "$RULE_NAME" '.rules[] | select(.name==$rule_name) | .enabled_prod'`
    echo "${RULE_NAME},${DEV_FLG},DEVELOPMENT" >> ./configs_org.csv
    echo "${RULE_NAME},${QA_FLG},QA" >> ./configs_org.csv
    echo "${RULE_NAME},${PROD_FLG},PRODUCTION" >> ./configs_org.csv
    echo "${RULE_NAME},${DEV_FLG},${QA_FLG},${PROD_FLG}" >> ./configs_app.csv
done < <(cat ./rules.json | jq -r '.rules[].name')

# 組織ごとにルールのon/offを反映していきます。
while read -r ORG_ID; do
    echo ""
    echo ${ORG_ID}
    ORG_API_KEY=`grep ${ORG_ID} ./orgid_apikey_map.txt | awk -F: '{print $2}'`

    if [ "${TARGET}" = "ALL" -o "${TARGET}" = "ORG" ]; then
        while read -r LINE; do
            NAME=`echo $LINE | awk -F, '{print $1}'`
            FLG=`echo $LINE | awk -F, '{print $2}'`
            ENVIRONMENT=`echo $LINE | awk -F, '{print $3}'`
            DATA=`jq --argjson flg "${FLG}" --arg environment "${ENVIRONMENT}" -nc '{"enabled":$flg,"environment":$environment}'`
            echo ""
            echo "${ORG_ID}:${NAME} ${DATA}"
            curl -X PUT -sS \
                ${API_URL}/${ORG_ID}/rules/${NAME}/status?expand=skip_links \
                -H "Authorization: ${AUTHORIZATION}" \
                -H "API-Key: ${ORG_API_KEY}" \
                -H "Content-Type: application/json" \
                -H 'Accept: application/json' \
                -d "${DATA}"
            sleep 0.5
        done < ./configs_org.csv
    fi

    if [ "${TARGET}" = "ALL" -o "${TARGET}" = "APP" ]; then
        rm -f ./applications.json
        curl -X GET -sS \
             ${API_URL}/${ORG_ID}/applications?expand=skip_links \
             -H "Authorization: ${AUTHORIZATION}" \
             -H "API-Key: ${ORG_API_KEY}" \
             -H 'Accept: application/json' -J -o applications.json

        while read -r APP_ID; do
            echo ""
            APP_NAME=`cat ./applications.json | jq -r --arg app_id "$APP_ID" '.applications[] | select(.app_id==$app_id) | .name'`
            echo "${ORG_ID}:${APP_ID} - ${APP_NAME}"
            while read -r LINE; do
                NAME=`echo $LINE | awk -F, '{print $1}'`
                DEV=`echo $LINE | awk -F, '{print $2}'`
                QA=`echo $LINE | awk -F, '{print $3}'`
                PROD=`echo $LINE | awk -F, '{print $4}'`
                DATA=`jq --arg name "${NAME}" --argjson dev "${DEV}" --argjson qa "${QA}" --argjson prod "${PROD}" -nc '{rule_names:[$name],"dev_enabled":$dev,"qa_enabled":$qa,"prod_enabled":$prod}'`
                echo ""
                echo "${ORG_ID}:${APP_ID} - ${APP_NAME} ${NAME} ${DATA}"
                curl -X PUT -sS \
                    ${API_URL}/${ORG_ID}/assess/rules/configs/app/${APP_ID}/bulk?expand=skip_links \
                    -H "Authorization: ${AUTHORIZATION}" \
                    -H "API-Key: ${ORG_API_KEY}" \
                    -H "Content-Type: application/json" \
                    -H 'Accept: application/json' \
                    -d "${DATA}"
                sleep 0.5
            done < ./configs_app.csv
            sleep 1
        done < <(cat ./applications.json | jq -r '.applications[].app_id')
    fi
done < <(cat ./org_ids.txt)

exit 0

