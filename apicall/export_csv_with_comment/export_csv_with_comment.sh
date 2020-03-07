#!/bin/sh

CONTRAST_URL="https://eval.contrastsecurity.com/Contrast"
AUTH_HEADER="dHVyYm91QGkuc29mdGJhbmsuanA6OVNRWjA3SVlQVjQ4WkRBVQ=="
API_KEY="EFhK6pIuD6mh5RX6YQ2iMOOavh9Mc52u"

ORG_ID="442311fd-c9d6-44a9-a00b-2b03db2d816c"
APP_ID="5be21fa1-e0d8-45d7-baed-a2fd4a3de1c8"

echo "DOWNLOAD VULNS CSV WITH COMMENT"
curl -X POST -sS \
     ${CONTRAST_URL}/api/ng/${ORG_ID}/orgtraces/export/csv/all \
     -H "Authorization: ${AUTH_HEADER}" \
     -H "API-Key: ${API_KEY}" \
     -o output.zip -f
STS=$?
if [ $STS -ne 0 ]; then
    rm -f ./output.zip
    exit 1
fi

unzip -o ./output.zip -d output_csv_dir
rm -f ./output.zip

find ./output_csv_dir -maxdepth 1 -name "*.csv" | while read -r filepath; do
    cat ${filepath} | while read LINE; do
        echo $LINE
    done
done

exit 0

