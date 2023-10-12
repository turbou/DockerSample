import os
import json
import html
import requests
import csv
import argparse
from datetime import datetime as dt

def main():
    parser = argparse.ArgumentParser(
        prog='suppress.py', # プログラム名
        usage='Demonstration of argparser', # プログラムの利用方法
        description='description', # 引数のヘルプの前に表示
        epilog='end', # 引数のヘルプの後で表示
        add_help=True, # -h/–help オプションの追加
    )
    parser.add_argument('--showrule', help='Protectのルール一覧を表示だけ', action='store_true')
    parser.add_argument('--app', help='アプリケーションID')
    parser.add_argument('--rule', help='ルールID（例：sql-injection）')
    parser.add_argument('--startdate', help='YYYYMMDD')
    parser.add_argument('--enddate', help='YYYYMMDD')
    parser.add_argument('--env', help='DEVELOPMENT|QA|PRODUCTION')
    args = parser.parse_args()

    env_not_found = False
    for env_key in ['CONTRAST_BASEURL', 'CONTRAST_AUTHORIZATION', 'CONTRAST_API_KEY', 'CONTRAST_ORG_ID']:
        if not env_key in os.environ:
            print('Environment variable %s is not set' % env_key)
            env_not_found |= True
    if env_not_found:
        print()
        print('CONTRAST_BASEURL                   : https://eval.contrastsecurity.com/Contrast')
        print('CONTRAST_AUTHORIZATION             : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX==')
        print('CONTRAST_API_KEY                   : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX')
        print('CONTRAST_ORG_ID                    : XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX')
        print()
        return
    BASEURL=os.environ['CONTRAST_BASEURL']
    API_KEY=os.environ['CONTRAST_API_KEY']
    AUTHORIZATION=os.environ['CONTRAST_AUTHORIZATION']
    ORG_ID=os.environ['CONTRAST_ORG_ID']
    headers = {"Accept": "application/json", "content-type": "application/json", "API-Key": API_KEY, "Authorization": AUTHORIZATION}
    API_URL="%s/api/ng/%s" % (BASEURL, ORG_ID)
    if args.showrule:
        url_rules = '%s/protection/rules/rules?expand=app_protect_rules,skip_links&q=&quickFilter=ALL&sort=name' % API_URL
        r = requests.get(url_rules, headers=headers)
        data = r.json()
        #print(json.dumps(data, indent=4))
        for rule in data['rules']:
            print('%-50s: %s' % (rule['uuid'], rule['name']))
        return

    if args.app is None or args.rule is None or args.env is None or args.startdate is None or args.enddate is None:
        parser.print_help()
        return

    APP_ID=args.app
    RULE_ID = args.rule
    ENV=args.env
    START_DATE = '%s000000' % args.startdate
    END_DATE = '%s235959' % args.enddate

    start_unix_time = int(dt.strptime(START_DATE, '%Y%m%d%H%M%S').timestamp() * 1000)
    end_unix_time = int(dt.strptime(END_DATE, '%Y%m%d%H%M%S').timestamp() * 1000)
    print(start_unix_time, end_unix_time)

    # =============== 攻撃イベント一覧を取得 ===============
    all_attack_events = []
    url_attackevents = '%s/rasp/events/new?expand=skip_links&limit=15&offset=%d&sort=-timestamp' % (API_URL, len(all_attack_events))
    payload = '{"quickFilter":"ALL","rules":["%s"],"applications":["%s"],"startDate":"%d","endDate":"%d","environments":["%s"]}' % (
        RULE_ID, APP_ID, start_unix_time, end_unix_time, ENV
    )
    r = requests.post(url_attackevents, headers=headers, data=payload)
    data = r.json()
    #print(json.dumps(data, indent=4))
    totalCnt = data['count']
    #print(totalCnt)
    for event in data['events']:
        print(event['event_uuid'])
        all_attack_events.append(event['event_uuid'])

    attackIncompleteFlg = True
    attackIncompleteFlg = totalCnt > len(all_attack_events)
    while attackIncompleteFlg:
        url_attackevents = '%s/rasp/events/new?expand=skip_links&limit=15&offset=%d&sort=-timestamp' % (API_URL, len(all_attack_events))
        payload = '{"quickFilter":"ALL","rules":["%s"],"applications":["%s"],"startDate":"%d","endDate":"%d","environments":["%s"]}' % (
            RULE_ID, APP_ID, start_unix_time, end_unix_time, ENV
        )
        r = requests.post(url_attackevents, headers=headers, data=payload)
        data = r.json()
        for event in data['events']:
            print(event['event_uuid'])
            all_attack_events.append(event['event_uuid'])
        attackIncompleteFlg = totalCnt > len(all_attack_events)
    print('Total(AttackEvent): ', len(all_attack_events))

    # =============== 最後に対象の攻撃イベントに対して消去を実行 ===============
    for attack_event in all_attack_events:
         print(attack_event)
    #    url_attackevent_suppress = '%s/rasp/events/%s/suppress?expand=skip_links' % (API_URL, attack_event)
    #    payload = '{"suppress_similar":false}'
    #    r = requests.put(url_attackevent_suppress, headers=headers, data=payload)
    #    data = r.json()
    #    print(json.dumps(data, indent=4))

if __name__ == '__main__':
    main()

