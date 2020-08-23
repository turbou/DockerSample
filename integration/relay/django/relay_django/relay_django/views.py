from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from django.http import HttpResponse
from django.conf import settings

import json
import requests
import re

def callAPI(url):
    headers = {
        'Authorization': settings.AUTHORIZATION,
        'API-Key': settings.API_KEY,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
    }
    res = requests.get(url, headers=headers)
    return res

def convertMustache(old_str):
    # Link
    #new_str = old_str.gsub(/{{#link}}(.+?)\$\$LINK_DELIM\$\$(.+?){{\/link}}/, '[\2](\1)')
    new_str = re.sub(r'{{#link}}(.+?)\$\$LINK_DELIM\$\$(.+?){{\/link}}', r'[\2](\1)', old_str)
    # CodeBlock
    #new_str = new_str.gsub(/{{#[A-Za-z]+Block}}/, "~~~\n").gsub(/{{\/[A-Za-z]+Block}}/, "\n~~~")
    new_str = re.sub(r'{{#[A-Za-z]+Block}}', '~~~\n', new_str)
    new_str = re.sub(r'{{\/[A-Za-z]+Block}}', '\n~~~', new_str)
    # Header
    #new_str = new_str.gsub(/{{#header}}/, '### ').gsub(/{{\/header}}/, '')
    new_str = new_str.replace('{{#header}}', '### ').replace('{{\/header}}', '')
    # List
    #new_str = new_str.gsub(/{{#listElement}}/, '* ').gsub(/{{\/listElement}}/, '')
    new_str = new_str.replace('{{#listElement}}', '* ').replace('{{\/listElement}}', '')
    # Other
    #new_str = new_str.gsub(/{{(#|\/)[A-Za-z]+}}/, '')
    new_str = re.sub(r'{{(#|\/)[A-Za-z]+}}', '', new_str)
    # <, >
    #new_str = new_str.gsub(/&lt;/, '<').gsub(/&gt;/, '>')
    new_str = new_str.replace('&lt;', '<').replace('&gt;', '>')
    return new_str

@require_http_methods(["GET", "POST", "PUT"])
@csrf_exempt
def hook(request):
    print('oyoyo')
    print(request.body)
    if request.method == 'POST':
        return HttpResponse(status=200)
    elif request.method == 'PUT':
        return HttpResponse(status=200)
    return HttpResponse(status=404)

@require_http_methods(["GET", "POST", "PUT"])
@csrf_exempt
def vote(request, key=None):
    if request.method == 'POST':
        json_data = json.loads(request.body)
        print(key)
        print(json_data)
        if json_data['event_type'] == 'TEST_CONNECTION':
            return HttpResponse(status=200)
        elif json_data['event_type'] == 'NEW_VULNERABILITY':
            print(json_data['description'])
            app_name = json_data['application_name']
            self_url = ''
            r = re.compile(".+\((.+)\) was found in")
            m = r.search(json_data['description'])
            if m is not None:
                self_url = m.group(1)

            r = re.compile("index.html#/(.+)/applications/(.+)/vulns/(.+)\) was found in")
            m = r.search(json_data['description'])
            if m is None:
                return HttpResponse(status=200)
            org_id = m.group(1)
            app_id = m.group(2)
            vul_id = m.group(3)
            teamserver_url = settings.TEAMSERVER_URL
            url = '%s/api/ng/%s/traces/%s/trace/%s?expand=servers,application' % (teamserver_url, org_id, app_id, vul_id)
            res = callAPI(url)
            vuln_json = res.json()
            summary = '[%s] %s' % (app_name, vuln_json['trace']['title'])
            story_url = ''
            howtofix_url = ''
            for c_link in vuln_json['trace']['links']:
                if c_link['rel'] == 'story':
                    story_url = c_link['href']
                    if '{traceUuid}' in story_url:
                        story_url = story_url.replace('{traceUuid}', vul_id)
                if c_link['rel'] == 'recommendation':
                    howtofix_url = c_link['href']
                    if '{traceUuid}' in howtofix_url:
                        howtofix_url = howtofix_url.replace('{traceUuid}', vul_id)
            # Story
            get_story_res = callAPI(story_url)
            story_json = get_story_res.json()
            story = story_json['story']['risk']['formattedText']
            # How to fix
            get_howtofix_res = callAPI(howtofix_url)
            howtofix_json = get_howtofix_res.json()
            howtofix = howtofix_json['recommendation']['formattedText']

            deco_mae = "## "
            deco_ato = ""
            description = []
            description.append('%s%s%s\n' % (deco_mae, '概要', deco_ato))
            description.append('%s\n\n' %  (convertMustache(story)))
            description.append('%s%s%s\n' % (deco_mae, '修正方法', deco_ato))
            description.append('%s\n\n' %  (convertMustache(howtofix)))
            description.append('%s%s%s\n' % (deco_mae, '脆弱性URL', deco_ato))
            description.append(self_url)

            project_id = json_data['projectId']
            issue_type_id = json_data['issueTypeId']
            priority_id = json_data['priorityId']
            url = '%s/api/v2/issues?apiKey=%s' % (settings.BACKLOG_URL, key)
            # projectId=97197&summary=$Title+$VulnerabilityRule&issueTypeId=456121&priorityId=3&description=$Message
            #payload = {'projectId': json_data['project'], 'summary': json_data['vulnerability_rule']}
            data = {
                'projectId': project_id,
                'summary': summary,
                'issueTypeId': issue_type_id,
                'priorityId': priority_id,
                'description': ''.join(description),
            }   
            headers = {
                'Content-Type': 'application/json'
            }
            res = requests.post(url, json=data, headers=headers)
            print(res.status_code)
            print(res.json())
            if res.status_code == 201:
                return HttpResponse(json.dumps({'messages': res.json()}), content_type='application/json', status=200)
            else:
                return HttpResponse(json.dumps({'messages': res.json()}), content_type='application/json', status=res.status_code)
        elif json_data['event_type'] == 'NEW_VULNERABLE_LIBRARY':
            r = re.compile(".+ was found in ([^(]+) \(.+index.html#\/(.+)\/.+\/(.+)\/([^)]+)\),.+\/applications\/([^)]+)\).")
            m = r.search(json_data['description'])
            if m is None:
                return HttpResponse(status=200)
            lib_name = m.group(1)
            org_id = m.group(2)
            app_id = m.group(5)
            lib_lang = m.group(3)
            lib_id = m.group(4)
            teamserver_url = settings.TEAMSERVER_URL
            url = '%s/api/ng/%s/libraries/%s/%s?expand=vulns' % (teamserver_url, org_id, lib_lang, lib_id)
            res = callAPI(url)
            lib_json = res.json()
            file_version = lib_json['library']['file_version']
            latest_version = lib_json['library']['latest_version']
            classes_used = lib_json['library']['classes_used']
            class_count = lib_json['library']['class_count']
            cve_list = []
            for c_link in lib_json['library']['vulns']:
                cve_list.append(c_link['name'])
            r = re.compile(".+ was found in .+\((.+)\),.+")
            m = r.search(json_data['description'])
            self_url = ''
            if m is not None:
                self_url = m.group(1)
            summary = lib_name
            # description
            deco_mae = "**"
            deco_ato = "**"
            description = []
            description.append('%s%s%s\n' % (deco_mae, '現在バージョン', deco_ato))
            description.append('%s\n\n' % (file_version))
            description.append('%s%s%s\n' % (deco_mae, '最新バージョン', deco_ato))
            description.append('%s\n\n' % (latest_version))
            description.append('%s%s%s\n' % (deco_mae, 'クラス(使用/全体)', deco_ato))
            description.append('%d/%d\n\n' % (classes_used, class_count))
            description.append('%s%s%s\n' % (deco_mae, '脆弱性', deco_ato))
            description.append('%s\n\n' % ('\n'.join(cve_list)))
            description.append('%s%s%s\n' % (deco_mae, 'ライブラリURL', deco_ato))
            description.append(self_url)

            project_id = json_data['projectId']
            issue_type_id = json_data['issueTypeId']
            priority_id = json_data['priorityId']
            url = '%s/api/v2/issues?apiKey=%s' % (settings.BACKLOG_URL, key)
            data = {
                'projectId': project_id,
                'summary': summary,
                'issueTypeId': issue_type_id,
                'priorityId': priority_id,
                'description': ''.join(description),
            }   
            headers = {
                'Content-Type': 'application/json'
            }
            res = requests.post(url, json=data, headers=headers)
            print(res.status_code)
            #print(res.json())
            if res.status_code == 201:
                return HttpResponse(json.dumps({'messages': res.json()}), content_type='application/json', status=200)
            else:
                return HttpResponse(json.dumps({'messages': res.json()}), content_type='application/json', status=res.status_code)
        else:
            return HttpResponse(status=200)
    elif request.method == 'PUT':
        return HttpResponse(status=200)
    return HttpResponse(status=404)

@require_http_methods(["GET", "POST", "PUT"])
@csrf_exempt
def vote2(request, key=None):
    if request.method == 'POST':
        json_data = json.loads(request.body)
        print(key)
        print(json_data)
        if json_data['event_type'] == 'TEST_CONNECTION':
            return HttpResponse(status=200)
        elif json_data['event_type'] == 'NEW_VULNERABILITY':
            print(json_data['description'])
            app_name = json_data['application_name']
            self_url = ''
            r = re.compile(".+\((.+)\) was found in")
            m = r.search(json_data['description'])
            if m is not None:
                self_url = m.group(1)

            r = re.compile("index.html#/(.+)/applications/(.+)/vulns/(.+)\) was found in")
            m = r.search(json_data['description'])
            if m is None:
                return HttpResponse(status=200)
            org_id = m.group(1)
            app_id = m.group(2)
            vul_id = m.group(3)
            teamserver_url = settings.TEAMSERVER_URL
            url = '%s/api/ng/%s/traces/%s/trace/%s?expand=servers,application' % (teamserver_url, org_id, app_id, vul_id)
            res = callAPI(url)
            vuln_json = res.json()
            summary = '[%s] %s' % (app_name, vuln_json['trace']['title'])
            story_url = ''
            howtofix_url = ''
            for c_link in vuln_json['trace']['links']:
                if c_link['rel'] == 'story':
                    story_url = c_link['href']
                    if '{traceUuid}' in story_url:
                        story_url = story_url.replace('{traceUuid}', vul_id)
                if c_link['rel'] == 'recommendation':
                    howtofix_url = c_link['href']
                    if '{traceUuid}' in howtofix_url:
                        howtofix_url = howtofix_url.replace('{traceUuid}', vul_id)
            # Story
            get_story_res = callAPI(story_url)
            story_json = get_story_res.json()
            story = story_json['story']['risk']['formattedText']
            # How to fix
            get_howtofix_res = callAPI(howtofix_url)
            howtofix_json = get_howtofix_res.json()
            howtofix = howtofix_json['recommendation']['formattedText']

            deco_mae = "## "
            deco_ato = ""
            description = []
            description.append('%s%s%s\n' % (deco_mae, '概要', deco_ato))
            description.append('%s\n\n' %  (convertMustache(story)))
            description.append('%s%s%s\n' % (deco_mae, '修正方法', deco_ato))
            description.append('%s\n\n' %  (convertMustache(howtofix)))
            description.append('%s%s%s\n' % (deco_mae, '脆弱性URL', deco_ato))
            description.append(self_url)

            project_id = json_data['projectId']
            labels = json_data['labels']
            priority_id = json_data['priorityId']
            url = '%s/api/v4/projects/%s/issues' % (settings.GITLAB_URL, project_id)
            data = {
                'title': summary,
                'labels': labels,
                'description': ''.join(description),
            }   
            headers = {
                'Content-Type': 'application/json',
                'PRIVATE-TOKEN': key
            }
            res = requests.post(url, json=data, headers=headers)
            print(res.status_code)
            print(res.json())
            return HttpResponse(status=200)
        elif json_data['event_type'] == 'NEW_VULNERABLE_LIBRARY':
            r = re.compile(".+ was found in ([^(]+) \(.+index.html#\/(.+)\/.+\/(.+)\/([^)]+)\),.+\/applications\/([^)]+)\).")
            m = r.search(json_data['description'])
            if m is None:
                return HttpResponse(status=200)
            lib_name = m.group(1)
            org_id = m.group(2)
            app_id = m.group(5)
            lib_lang = m.group(3)
            lib_id = m.group(4)
            teamserver_url = settings.TEAMSERVER_URL
            url = '%s/api/ng/%s/libraries/%s/%s?expand=vulns' % (teamserver_url, org_id, lib_lang, lib_id)
            res = callAPI(url)
            lib_json = res.json()
            file_version = lib_json['library']['file_version']
            latest_version = lib_json['library']['latest_version']
            classes_used = lib_json['library']['classes_used']
            class_count = lib_json['library']['class_count']
            cve_list = []
            for c_link in lib_json['library']['vulns']:
                cve_list.append(c_link['name'])
            r = re.compile(".+ was found in .+\((.+)\),.+")
            m = r.search(json_data['description'])
            self_url = ''
            if m is not None:
                self_url = m.group(1)
            summary = lib_name
            # description
            deco_mae = "**"
            deco_ato = "**"
            description = []
            description.append('%s%s%s\n' % (deco_mae, '現在バージョン', deco_ato))
            description.append('%s\n\n' % (file_version))
            description.append('%s%s%s\n' % (deco_mae, '最新バージョン', deco_ato))
            description.append('%s\n\n' % (latest_version))
            description.append('%s%s%s\n' % (deco_mae, 'クラス(使用/全体)', deco_ato))
            description.append('%d/%d\n\n' % (classes_used, class_count))
            description.append('%s%s%s\n' % (deco_mae, '脆弱性', deco_ato))
            description.append('%s\n\n' % ('\n'.join(cve_list)))
            description.append('%s%s%s\n' % (deco_mae, 'ライブラリURL', deco_ato))
            description.append(self_url)

            project_id = json_data['projectId']
            labels = json_data['labels']
            priority_id = json_data['priorityId']
            url = '%s/api/v4/projects/%s/issues' % (settings.GITLAB_URL, project_id)
            data = {
                'title': summary,
                'labels': labels,
                'description': ''.join(description),
            }   
            headers = {
                'Content-Type': 'application/json',
                'PRIVATE-TOKEN': key
            }
            res = requests.post(url, json=data, headers=headers)
            print(res.status_code)
            #print(res.json())
            if res.status_code == 201:
                return HttpResponse(json.dumps({'messages': res.json()}), content_type='application/json', status=200)
            else:
                return HttpResponse(json.dumps({'messages': res.json()}), content_type='application/json', status=res.status_code)
        else:
            return HttpResponse(status=200)
    elif request.method == 'PUT':
        return HttpResponse(status=200)
    return HttpResponse(status=404)

