import os
import json
import html
import requests
import csv
from datetime import datetime

def main():
    env_not_found = False
    for env_key in ['CONTRAST_BASEURL', 'CONTRAST_AUTHORIZATION', 'CONTRAST_API_KEY', 'CONTRAST_ORG_ID', 'CONTRAST_APP_ID', 'SUPPRESS_RULE_KEY']:
        if not env_key in os.environ:
            print('環境変数 %s が設定されていません。' % env_key)
            env_not_found |= True
    if env_not_found:
        print()
        print('CONTRAST_BASEURL                   : https://eval.contrastsecurity.com/Contrast')
        print('CONTRAST_AUTHORIZATION             : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX==')
        print('CONTRAST_API_KEY                   : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX')
        print('CONTRAST_ORG_ID                    : XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX')
        print('CONTRAST_APP_ID                    : XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX')
        print('SUPPRESS_RULE_KEY                  : XXXXXXXX')
        print()
        return

    BASEURL=os.environ['CONTRAST_BASEURL']
    API_KEY=os.environ['CONTRAST_API_KEY']
    AUTHORIZATION=os.environ['CONTRAST_AUTHORIZATION']
    ORG_ID=os.environ['CONTRAST_ORG_ID']
    APP_ID=os.environ['CONTRAST_APP_ID']
    API_URL="%s/api/ng/%s" % (BASEURL, ORG_ID)

    headers = {"Accept": "application/json", "API-Key": API_KEY, "Authorization": AUTHORIZATION}

    attack_uuids = []
    url_applications = '%s/applications' % (API_URL)
    url_attacks = '%s/attacks?expand=skip_links&limit=15&offset=0&sort=-startTime' % (API_URL)
    r = requests.get(url_attacks, headers=headers, json='{"quickFilter":"ALL","endDate":"%s"}' % ('1697381999287'))
    data = r.json()
    #print(json.dumps(data, indent=4))
    if not data['success']:
        print('Authorizationヘッダ, APIキー, 組織ID, TeamServerのURLが正しいか、ご確認ください。')
        return
    totalCnt = data['count']
    print(totalCnt)
    for attack in data['attacks']:
        attack_uuids.append(attack['uuid']) 
    print(len(attack_uuids))
    attackIncompleteFlg = True
    while attackIncompleteFlg:
        url_attacks = '%s/attacks?expand=skip_links&limit=15&offset=%d&sort=-startTime' % (API_URL, len(attack_uuids))
        r = requests.get(url_attacks, headers=headers, json='{"quickFilter":"ALL","endDate":"%s"}' % ('1697381999287'))
        data = r.json()
        if not data['success']:
            print('Authorizationヘッダ, APIキー, 組織ID, TeamServerのURLが正しいか、ご確認ください。')
            return
        for attack in data['attacks']:
            attack_uuids.append(attack['uuid']) 
        print(len(attack_uuids))
        attackIncompleteFlg = totalCnt > len(attack_uuids)

    print('Total: ', len(attack_uuids))

if __name__ == '__main__':
    main()

