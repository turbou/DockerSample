import requests
import json
import zipfile
import io
import html
from xml.etree import ElementTree
from datetime import datetime

CONTRAST_AUTHORIZATION="dHVyYm91QGkuc29mdGJhbmsuanA6OVNRWjA3SVlQVjQ4WkRBVQ=="
CONTRAST_API_KEY="EFhK6pIuD6mh5RX6YQ2iMOOavh9Mc52u"
CONTRAST_ORG="442311fd-c9d6-44a9-a00b-2b03db2d816c"
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
        if app['app_id'] != '5be21fa1-e0d8-45d7-baed-a2fd4a3de1c8':
            continue
        #print(json.dumps(data, indent=4))
        url_traces = '%s/traces/%s/ids' % (BASEURL, app['app_id'])
        r = requests.get(url_traces, headers=headers)
        data = r.json()
        #print(json.dumps(data, indent=4))
        for trace in data['traces']:
            url_trace = '%s/traces/%s/trace/%s' % (BASEURL, app['app_id'], trace)
            r = requests.get(url_trace, headers=headers)
            data = r.json()
            print(json.dumps(data, indent=4))
            print(data['trace']['title'])
            print(data['trace']['uuid'])
            print(data['trace']['category'])
            print(data['trace']['rule_name'])
            print(data['trace']['severity'])
            print(data['trace']['status'])
            print(datetime.fromtimestamp(data['trace']['first_time_seen']/1000).strftime('%Y/%m/%d %H:%M'))
            print(datetime.fromtimestamp(data['trace']['last_time_seen']/1000).strftime('%Y/%m/%d %H:%M'))
            print(app['app_id'])
            print(app['name'])
            print(app['code'])
            # How to Fix
            url_trace_howtofix = '%s/traces/%s/recommendation' % (BASEURL, trace)
            r = requests.get(url_trace_howtofix, headers=headers)
            data = r.json()
            #print(json.dumps(data, indent=4))
            print(data['cwe'])

            # Comments
            url_trace_notes = '%s/applications/%s/traces/%s/notes' % (BASEURL, app['app_id'], trace)
            r = requests.get(url_trace_notes, headers=headers)
            data = r.json()
            #print(json.dumps(data, indent=4))
            for note in data['notes']:
                print(html.unescape(note['note']))

if __name__ == '__main__':
    main()

