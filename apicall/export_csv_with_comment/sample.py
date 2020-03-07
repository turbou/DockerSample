import requests
import json
import zipfile
import io
import html
from xml.etree import ElementTree
from datetime import datetime

CONTRAST_AUTHORIZATION="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX=="
CONTRAST_API_KEY="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
CONTRAST_ORG="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
## Teamserver URL
BASEURL="https://eval.contrastsecurity.com/Contrast/api/ng/%s" % CONTRAST_ORG

def main():
    headers = {"Accept": "application/json", "API-Key": CONTRAST_API_KEY, "Authorization": CONTRAST_AUTHORIZATION}
    url_applications = '%s/applications' % (BASEURL)
    r = requests.get(url_applications, headers=headers)
    data = r.json()
    #print(json.dumps(data, indent=4))
    if not data['success']:
        print('Authorizationヘッダ, APIキー, 組織ID, TeamServerのURLが正しいか、ご確認ください。')
        return
    #print(len(data['traces']))
    print(len(data['applications']))
    for app in data['applications']:
        out_line = []
        #if app['app_id'] != '5be21fa1-e0d8-45d7-baed-a2fd4a3de1c8':
        #    continue
        #print(json.dumps(data, indent=4))
        url_traces = '%s/traces/%s/ids' % (BASEURL, app['app_id'])
        r = requests.get(url_traces, headers=headers)
        data = r.json()
        #print(json.dumps(data, indent=4))
        for trace in data['traces']:
            url_trace = '%s/traces/%s/trace/%s' % (BASEURL, app['app_id'], trace)
            r = requests.get(url_trace, headers=headers)
            data = r.json()
            #print(json.dumps(data, indent=4))
            #print(data['trace']['title'])
            out_line.append(data['trace']['title'])
            #print(data['trace']['uuid'])
            out_line.append(data['trace']['uuid'])
            #print(data['trace']['category'])
            out_line.append(data['trace']['category'])
            #print(data['trace']['rule_name'])
            out_line.append(data['trace']['rule_name'])
            #print(data['trace']['severity'])
            out_line.append(data['trace']['severity'])
            #print(data['trace']['status'])
            out_line.append(data['trace']['status'])
            #print(datetime.fromtimestamp(data['trace']['first_time_seen']/1000).strftime('%Y/%m/%d %H:%M'))
            out_line.append(datetime.fromtimestamp(data['trace']['first_time_seen']/1000).strftime('%Y/%m/%d %H:%M'))
            #print(datetime.fromtimestamp(data['trace']['last_time_seen']/1000).strftime('%Y/%m/%d %H:%M'))
            out_line.append(datetime.fromtimestamp(data['trace']['last_time_seen']/1000).strftime('%Y/%m/%d %H:%M'))
            #print(app['app_id'])
            out_line.append(app['app_id'])
            #print(app['name'])
            out_line.append(app['name'])
            #print(app['code'])
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

