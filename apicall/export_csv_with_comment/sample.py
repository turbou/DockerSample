import os
import json
import html
import requests
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
        print('BASEURL               : https://eval.contrastsecurity.com/Contrast')
        print('CONTRAST_AUTHORIZATION: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX==')
        print('CONTRAST_API_KEY      : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX')
        print('CONTRAST_ORG_ID       : XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX')
        return

    # Print Header
    print(','.join(CSV_HEADER))

    CONTRAST_BASEURL=os.environ['CONTRAST_BASEURL']
    CONTRAST_API_KEY=os.environ['CONTRAST_API_KEY']
    CONTRAST_AUTHORIZATION=os.environ['CONTRAST_AUTHORIZATION']
    CONTRAST_ORG_ID=os.environ['CONTRAST_ORG_ID']
    BASEURL="%s/api/ng/%s" % (CONTRAST_BASEURL, CONTRAST_ORG_ID)

    headers = {"Accept": "application/json", "API-Key": CONTRAST_API_KEY, "Authorization": CONTRAST_AUTHORIZATION}

    url_applications = '%s/applications' % (BASEURL)
    r = requests.get(url_applications, headers=headers)
    data = r.json()
    #print(json.dumps(data, indent=4))
    if not data['success']:
        print('Authorizationヘッダ, APIキー, 組織ID, TeamServerのURLが正しいか、ご確認ください。')
        return
    #print(len(data['traces']))
    #print('総アプリケーション数: %d' % len(data['applications']))
    for app in data['applications']:
        #if app['app_id'] != '5be21fa1-e0d8-45d7-baed-a2fd4a3de1c8':
        #    continue
        #print(json.dumps(data, indent=4))
        url_traces = '%s/traces/%s/ids' % (BASEURL, app['app_id'])
        r = requests.get(url_traces, headers=headers)
        data = r.json()
        #print(json.dumps(data, indent=4))
        for trace in data['traces']:
            out_line = []
            url_trace = '%s/traces/%s/trace/%s' % (BASEURL, app['app_id'], trace)
            r = requests.get(url_trace, headers=headers)
            data = r.json()
            #print(json.dumps(data, indent=4))
            if not data['success']:
                continue
            out_line.append(data['trace']['title'])
            out_line.append(data['trace']['uuid'])
            out_line.append(data['trace']['category'])
            out_line.append(data['trace']['rule_name'])
            out_line.append(data['trace']['severity'])
            out_line.append(data['trace']['status'])
            out_line.append(datetime.fromtimestamp(data['trace']['first_time_seen']/1000).strftime('%Y/%m/%d %H:%M'))
            out_line.append(datetime.fromtimestamp(data['trace']['last_time_seen']/1000).strftime('%Y/%m/%d %H:%M'))
            out_line.append(app['name'])
            out_line.append(app['app_id'])
            out_line.append(app['code'])
            # How to Fix
            url_trace_howtofix = '%s/traces/%s/recommendation' % (BASEURL, trace)
            r = requests.get(url_trace_howtofix, headers=headers)
            data = r.json()
            #print(json.dumps(data, indent=4))
            #print(data['cwe'])
            out_line.append(data['cwe'])

            # Comments
            url_trace_notes = '%s/applications/%s/traces/%s/notes' % (BASEURL, app['app_id'], trace)
            r = requests.get(url_trace_notes, headers=headers)
            data = r.json()
            #print(json.dumps(data, indent=4))
            for note in data['notes']:
                #print(html.unescape(note['note']))
                out_line.append(html.unescape(note['note']))

            maped_out_line = map(str, out_line)
            print(','.join(maped_out_line))

if __name__ == '__main__':
    main()

