import os
import json
import html
import requests
import csv
from datetime import datetime

CSV_HEADER=[
    'Vulnerability Name',
    'Vulnerability ID', 
    'Category',
    'Rule Name',
    'Severity',
    'Status',
    'First Seen Datetime',
    'Last Seen Datetime',
    'Application Name',
    'Application ID', 
    'Application Code',
    'CWE ID',
    'COMMENT',
]

def main():
    env_not_found = False
    for env_key in ['CONTRAST_BASEURL', 'CONTRAST_AUTHORIZATION', 'CONTRAST_API_KEY', 'CONTRAST_ORG_ID']:
        if not env_key in os.environ:
            print('環境変数 %s が設定されていません。' % env_key)
            env_not_found |= True
    if env_not_found:
        print()
        print('CONTRAST_BASEURL          : https://eval.contrastsecurity.com/Contrast')
        print('CONTRAST_AUTHORIZATION    : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX==')
        print('CONTRAST_API_KEY          : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX')
        print('CONTRAST_ORG_ID           : XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX')
        print('CONTRAST_APP_ID(optional) : XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX')
        return

    BASEURL=os.environ['CONTRAST_BASEURL']
    API_KEY=os.environ['CONTRAST_API_KEY']
    AUTHORIZATION=os.environ['CONTRAST_AUTHORIZATION']
    ORG_ID=os.environ['CONTRAST_ORG_ID']
    API_URL="%s/api/ng/%s" % (BASEURL, ORG_ID)
    APP_ID=None
    if 'CONTRAST_APP_ID' in os.environ:
        APP_ID=os.environ['CONTRAST_APP_ID']

    headers = {"Accept": "application/json", "API-Key": API_KEY, "Authorization": AUTHORIZATION}

    url_applications = '%s/applications' % (API_URL)
    r = requests.get(url_applications, headers=headers)
    data = r.json()
    #print(json.dumps(data, indent=4))
    if not data['success']:
        print('Authorizationヘッダ, APIキー, 組織ID, TeamServerのURLが正しいか、ご確認ください。')
        return
    #print(len(data['traces']))
    #print('総アプリケーション数: %d' % len(data['applications']))
    csv_lines = []
    for app in data['applications']:
        if APP_ID and app['app_id'] != APP_ID:
            continue
        #print(json.dumps(data, indent=4))
        url_traces = '%s/traces/%s/ids' % (API_URL, app['app_id'])
        r = requests.get(url_traces, headers=headers)
        data = r.json()
        #print(json.dumps(data, indent=4))
        for trace in data['traces']:
            csv_line = []
            url_trace = '%s/traces/%s/trace/%s' % (API_URL, app['app_id'], trace)
            r = requests.get(url_trace, headers=headers)
            data = r.json()
            #print(json.dumps(data, indent=4))
            if not data['success']:
                continue
            csv_line.append(data['trace']['title'])
            csv_line.append(data['trace']['uuid'])
            csv_line.append(data['trace']['category'])
            csv_line.append(data['trace']['rule_name'])
            csv_line.append(data['trace']['severity'])
            csv_line.append(data['trace']['status'])
            csv_line.append(datetime.fromtimestamp(data['trace']['first_time_seen']/1000).strftime('%Y/%m/%d %H:%M'))
            csv_line.append(datetime.fromtimestamp(data['trace']['last_time_seen']/1000).strftime('%Y/%m/%d %H:%M'))
            csv_line.append(app['name'])
            csv_line.append(app['app_id'])
            csv_line.append(app['code'])
            # How to Fix
            url_trace_howtofix = '%s/traces/%s/recommendation' % (API_URL, trace)
            r = requests.get(url_trace_howtofix, headers=headers)
            data = r.json()
            #print(json.dumps(data, indent=4))
            #print(data['cwe'])
            csv_line.append(data['cwe'])

            # Comments
            url_trace_notes = '%s/applications/%s/traces/%s/notes' % (API_URL, app['app_id'], trace)
            r = requests.get(url_trace_notes, headers=headers)
            data = r.json()
            #print(json.dumps(data, indent=4))
            for note in data['notes']:
                #print(html.unescape(note['note']))
                csv_line.append(html.unescape(note['note']))

            #maped_csv_line = map(str, csv_line)
            #print(','.join(maped_csv_line))
            csv_lines.append(csv_line)

    with open('result.csv', 'w', encoding='shift_jis') as f:
        writer = csv.writer(f, lineterminator='\n')
        writer.writerow(CSV_HEADER)
        writer.writerows(csv_lines)

if __name__ == '__main__':
    main()

