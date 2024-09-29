# This code sample uses the 'requests' library:
# http://docs.python-requests.org
from requests.auth import HTTPBasicAuth
import json
import os
import html
import requests
import csv
import re
from datetime import datetime

# Number of vulnerabilities to fetch per request.
LIMIT=25

def main():
    env_not_found = False
    for env_key in ['CONTRAST_BASEURL', 'CONTRAST_AUTHORIZATION', 'CONTRAST_API_KEY', 'CONTRAST_ORG_ID', 'CONTRAST_APP_ID', 'CONTRAST_JIRA_USER', 'CONTRAST_JIRA_API_TOKEN', 'CONTRAST_JIRA_TICKET_ID']:
        if not env_key in os.environ:
            print('Environment variable is not set. %s' % env_key)
            env_not_found |= True
    if env_not_found:
        print()
        print('Please set the environment variables as follows:')
        print('CONTRAST_BASEURL                   : https://eval.contrastsecurity.com/Contrast')
        print('CONTRAST_AUTHORIZATION             : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX==')
        print('CONTRAST_API_KEY                   : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX')
        print('CONTRAST_ORG_ID                    : XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX')
        print('CONTRAST_APP_ID                    : XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX')
        print('CONTRAST_JIRA_USER                 : xxxx.yyyy@contrastsecurity.com')
        print('CONTRAST_JIRA_API_TOKEN            : YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY')
        print('CONTRAST_JIRA_TICKET_ID            : FAKEBUG-12730')
        print('CONTRAST_METADATA_LABEL(optional)  : e.g. Branch Name')
        print('CONTRAST_METADATA_VALUE(optional)  : e.g. feature/oyoyo-001')
        return

    baseurl=os.environ['CONTRAST_BASEURL']
    api_key=os.environ['CONTRAST_API_KEY']
    authorization=os.environ['CONTRAST_AUTHORIZATION']
    org_id=os.environ['CONTRAST_ORG_ID']
    api_url="%s/api/ng/%s" % (baseurl, org_id)
    app_id=os.environ['CONTRAST_APP_ID']

    # Metadata specification is optional.
    metadata_label=''
    if 'CONTRAST_METADATA_LABEL' in os.environ and len(os.environ['CONTRAST_METADATA_LABEL']) > 0:
        metadata_label=os.environ['CONTRAST_METADATA_LABEL']
    metadata_value=''
    if 'CONTRAST_METADATA_VALUE' in os.environ and len(os.environ['CONTRAST_METADATA_VALUE']) > 0:
        metadata_value=os.environ['CONTRAST_METADATA_VALUE']
    if (len(metadata_label) > 0 and len(metadata_value) == 0) or (len(metadata_label) == 0 and len(metadata_value) > 0):
        print('If you want to specify session metadata, please provide both the label and value as environment variables.')
        return

    headers = {"Accept": "application/json", "Content-Type": "application/json", "API-Key": api_key, "Authorization": authorization}

    # Get the metadata filter ID from the given metadata label.
    metadata_id=None
    if len(metadata_label) > 0 and len(metadata_value) > 0:
        # Perform the following operations only if metadata information is provided.
        url_metadatas = '%s/metadata/session/%s/filters?expand=skip_links' % (api_url, app_id)
        r = requests.get(url_metadatas, headers=headers)
        data = r.json()
        #print(json.dumps(data, indent=4))
        if not data['success']:
            print('Please verify that the following are correct:')
            print('- TeamServer URL')
            print('- Authorization header')
            print('- API key')
            print('- Organization ID')
            return
        for f in data['filters']: 
            if f['agentLabel'] == metadata_label:
                metadata_id=f['id']
        #print(metadata_id)
    if metadata_id is None and len(metadata_label) > 0:
        print('The specified metadata filter was not found.')
        return

    # Fetch vulnerabilities for the target application. Filter by metadata if provided.
    all_traces = []
    url_traces = '%s/api/ng/organizations/%s/orgtraces/ui?expand=application&session_metadata&offset=%d&limit=%d&sort=-severity' % (baseurl, org_id, len(all_traces), LIMIT)
    payload = '{"modules":["%s"]}' % (app_id)
    if metadata_id:
        payload = '{"modules":["%s"],"metadataFilters":[{"fieldID":"%s","values":["%s"]}]}' % (app_id, metadata_id, metadata_value)
    r = requests.post(url_traces, headers=headers, data=payload)
    data = r.json()
    #print(json.dumps(data, indent=4))
    totalCnt = data['count']
    #print(totalCnt)
    for v in data['items']: 
        print(v['vulnerability']['severity'], v['vulnerability']['ruleName'])
        '''
        url_trace = '%s/api/ng/%s/traces/%s/filter/%s' % (baseurl, org_id, app_id, v['vulnerability']['uuid'])
        r = requests.get(url_trace, headers=headers)
        data = r.json()
        print(json.dumps(data, indent=4))
         https://eval.contrastsecurity.com/Contrast/static/ng/index.html#/442311fd-c9d6-44a9-a00b-2b03db2d816c/applications/0dbb3827-572b-47b0-9113-9d155e94e4f0/vulns/JJZ8-UOS4-POXP-GW0X?agentSessionId=16b57e3a1e9f4b8a7e72de256968f46d
        trace_link = ''
        for link in data['trace']['links']:
            if link['rel'] == 'self':
                trace_link = link['href']
                break
        '''
        trace_link = '%s/static/ng/index.html#/%s/applications/%s/vulns/%s' % (baseurl, org_id, app_id, v['vulnerability']['uuid'])
        all_traces.append(
            {
                'title': v['vulnerability']['title'],
                'severity': v['vulnerability']['severity'],
                'ruleName': v['vulnerability']['ruleName'],
                'uuid': v['vulnerability']['uuid'],
                'link': trace_link
            }
        )

    # This process iterates to ensure all vulnerabilities are retrieved, as there's a cap on the number fetched per request.
    traceIncompleteFlg = True
    traceIncompleteFlg = totalCnt > len(all_traces)
    while traceIncompleteFlg:
        url_traces = '%s/api/ng/organizations/%s/orgtraces/ui?expand=application&session_metadata&offset=%d&limit=%d&sort=-severity' % (baseurl, org_id, len(all_traces), LIMIT)
        payload = '{"modules":["%s"]}' % (app_id)
        if metadata_id:
            payload = '{"modules":["%s"],"metadataFilters":[{"fieldID":"%s","values":["%s"]}]}' % (app_id, metadata_id, metadata_value)
        r = requests.post(url_traces, headers=headers, data=payload)
        data = r.json()
        for v in data['items']: 
            print(v['vulnerability']['severity'], v['vulnerability']['ruleName'])
            '''
            url_trace = '%s/api/ng/%s/traces/%s/filter/%s' % (baseurl, org_id, app_id, v['vulnerability']['uuid'])
            r = requests.get(url_trace, headers=headers)
            data = r.json()
            #print(json.dumps(data, indent=4))
            trace_link = ''
            for link in data['trace']['links']:
                if link['rel'] == 'self':
                    trace_link = link['href']
                    break
            '''
            trace_link = '%s/static/ng/index.html#/%s/applications/%s/vulns/%s' % (baseurl, org_id, app_id, v['vulnerability']['uuid'])
            all_traces.append(
                {
                    'title': v['vulnerability']['title'],
                    'severity': v['vulnerability']['severity'],
                    'ruleName': v['vulnerability']['ruleName'],
                    'uuid': v['vulnerability']['uuid'],
                    'link': trace_link
                }
            )
        traceIncompleteFlg = totalCnt > len(all_traces)
    print('Total(Trace): ', len(all_traces))

    # The following code is responsible for commenting the retrieved vulnerabilities on the Jira ticket.
    jira_user=os.environ['CONTRAST_JIRA_USER']
    jira_token=os.environ['CONTRAST_JIRA_API_TOKEN']
    jira_ticket=os.environ['CONTRAST_JIRA_TICKET_ID']
    url = "https://contrast.atlassian.net/rest/api/3/issue/%s/comment" % (jira_ticket)
    auth = HTTPBasicAuth(
        jira_user,
        jira_token
    )
    headers = {
      "Accept": "application/json",
      "Content-Type": "application/json"
    }
    base_payload = json.dumps({
        "body": {
        	"version": 1,
        	"type": "doc",
        	"content": [
        		{
        			"type": "table",
        			"attrs": {
        				"isNumberColumnEnabled": False,
        				"layout": "center",
        				"width": 600,
        				"displayMode": "default"
        			},
        			"content": [
                        # Insert table block here.
        			]
        		}
        	]
        }
    })
    base_dict = json.loads(base_payload)
    row_dict_list = []
    # Table Header
    row_dict = {}
    row_dict['type'] = 'tableRow'
    cell_contents = [] 
    cell_contents.append({'type': 'tableHeader', 'attrs': {}, 'content': [{'type': 'paragraph', 'content': [{'type': 'text', 'text': 'Risk'}]}]})
    cell_contents.append({'type': 'tableHeader', 'attrs': {}, 'content': [{'type': 'paragraph', 'content': [{'type': 'text', 'text': 'Issut Type'}]}]})
    cell_contents.append({'type': 'tableHeader', 'attrs': {}, 'content': [{'type': 'paragraph', 'content': [{'type': 'text', 'text': 'Affected Path/Class'}]}]})
    cell_contents.append({'type': 'tableHeader', 'attrs': {}, 'content': [{'type': 'paragraph', 'content': [{'type': 'text', 'text': 'Details'}]}]})
    row_dict['content'] = cell_contents
    row_dict_list.append(row_dict)

    # Table Cell
    pattern = re.compile(r' from | on | at | in | : |：')
    pattern2 = re.compile(r'^.+?( from | on | at | in | : |：)(.+)$')
    for t in all_traces:
        row_dict = {}
        row_dict['type'] = 'tableRow'
        cell_contents = [] 
        cell_contents.append({'type': 'tableCell', 'attrs': {}, 'content': [{'type': 'paragraph', 'content': [{'type': 'text', 'text': t['severity']}]}]})
        cell_contents.append({'type': 'tableCell', 'attrs': {}, 'content': [{'type': 'paragraph', 'content': [{'type': 'text', 'text': t['ruleName']}]}]})
        title = t['title']
        if pattern.search(title):
            m = pattern2.match(title)
            if m:
                title = m.group(2)
        cell_contents.append({'type': 'tableCell', 'attrs': {}, 'content': [{'type': 'paragraph', 'content': [{'type': 'text', 'text': title}]}]})
        cell_contents.append({'type': 'tableCell', 'attrs': {}, 'content': [{'type': 'paragraph', 'content': [{'type': 'text', 'text': t['uuid'], 'marks': [{'type': 'link', 'attrs': {'href': t['link'], 'title': 'to TeamServer'}}]}]}]})
        row_dict['content'] = cell_contents
        row_dict_list.append(row_dict)
    base_dict['body']['content'][0]['content'] = row_dict_list
    payload = json.dumps(base_dict)

    response = requests.request(
       "POST",
       url,
       data=payload,
       headers=headers,
       auth=auth
    )
    print(json.dumps(json.loads(response.text), sort_keys=True, indent=4, separators=(",", ": "), ensure_ascii=False))

if __name__ == '__main__':
    main()

