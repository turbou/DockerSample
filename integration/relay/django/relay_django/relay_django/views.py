from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from django.http import HttpResponse
from integration.models import Integration
from application.models import Gitlab, GitlabMapping
from rest_framework.decorators import api_view, permission_classes, authentication_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework_jwt.authentication import JSONWebTokenAuthentication, BaseJSONWebTokenAuthentication
from django.utils.translation import gettext_lazy as _

import json
import requests
import re
import base64

def callAPI2(url, method, api_key, username, service_key, data=None):
    authorization = base64.b64encode(('%s:%s' % (username, service_key)).encode('utf-8'))
    print(authorization)
    headers = {
        'Authorization': authorization,
        'API-Key': api_key,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
    }
    if method == 'GET':
        res = requests.get(url, headers=headers)
    elif method == 'POST':
        pass
    elif method == 'PUT':
        res = requests.put(url, data=data, headers=headers)
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

class JSONWebTokenAuthenticationGitlab(BaseJSONWebTokenAuthentication):
    def get_jwt_value(self, request):
         return request.headers.get('X-Gitlab-Token')

@api_view(['GET', 'POST'])
@permission_classes((IsAuthenticated, ))
@authentication_classes((JSONWebTokenAuthenticationGitlab,))
def gitlab(request):
    print('posts!!')
    json_data = json.loads(request.body)
    if not 'event_type' in json_data:
        return HttpResponse(status=200)
    print(json_data['event_type'])
    if not 'action' in json_data['object_attributes']:
        return HttpResponse(status=200)
    if json_data['event_type'] != "issue":
        return HttpResponse(status=200)
    if json_data['object_attributes']['action'] == 'open':
        return HttpResponse(status=200)
    #print(json_data['object_attributes'].keys())
    print(json_data['object_attributes']['id'])
    print(json_data['object_attributes']['action'])
    gitlab_mapping = GitlabMapping.objects.filter(gitlab_issue_id=json_data['object_attributes']['id']).first()
    if gitlab_mapping is None:
        return HttpResponse(status=200)
    #print(gitlab_mapping.contrast_org_id)
    if json_data['user']['username'] == gitlab_mapping.gitlab.report_username:
        return HttpResponse(status=200)

    if json_data['object_attributes']['action'] == 'close':
        ts_config = gitlab_mapping.gitlab.integrations.first()
        teamserver_url = ts_config.url
        url = '%s/api/ng/%s/orgtraces/mark' % (teamserver_url, gitlab_mapping.contrast_org_id)
        data_dict = {'traces': [gitlab_mapping.contrast_vul_id], 'status': 'Remediated', 'note': 'closed by Gitlab.'}
        #res = callAPI(url, 'PUT', ts_config.authorization, ts_config.api_key, json.dumps(data_dict))
        res = callAPI2(url, 'PUT', ts_config.api_key, ts_config.username, ts_config.service_key, json.dumps(data_dict))
        print(res.text)
    elif json_data['object_attributes']['action'] == 'reopen':
        ts_config = gitlab_mapping.gitlab.integrations.first()
        teamserver_url = ts_config.url
        url = '%s/api/ng/%s/orgtraces/mark' % (teamserver_url, gitlab_mapping.contrast_org_id)
        data_dict = {'traces': [gitlab_mapping.contrast_vul_id], 'status': 'Reported'}
        #res = callAPI(url, 'PUT', ts_config.authorization, ts_config.api_key, json.dumps(data_dict))
        res = callAPI2(url, 'PUT', ts_config.api_key, ts_config.username, ts_config.service_key, json.dumps(data_dict))
        print(res.text)
    return HttpResponse(status=200)

@require_http_methods(["GET", "POST", "PUT"])
@csrf_exempt
def vote(request):
    if request.method == 'POST':
        json_data = json.loads(request.body)
        if json_data['event_type'] == 'TEST_CONNECTION':
            return HttpResponse(status=200)
        elif json_data['event_type'] == 'NEW_VULNERABILITY':
            print(json_data['description'])
            config_name = json_data.get('config_name')
            if config_name:
                ts_config = Integration.objects.get(name=config_name)
            else:
                ts_config = Integration.objects.first()
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
            teamserver_url = ts_config.url
            url = '%s/api/ng/%s/traces/%s/trace/%s?expand=servers,application' % (teamserver_url, org_id, app_id, vul_id)
            #res = callAPI(url, 'GET', ts_config.authorization, ts_config.api_key)
            res = callAPI2(url, 'GET', ts_config.api_key, ts_config.username, ts_config.service_key)
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
            #get_story_res = callAPI(story_url, 'GET', ts_config.authorization, ts_config.api_key)
            get_story_res = callAPI2(story_url, 'GET', ts_config.api_key, ts_config.username, ts_config.service_key)
            story_json = get_story_res.json()
            story = story_json['story']['risk']['formattedText']
            # How to fix
            #get_howtofix_res = callAPI(howtofix_url, 'GET', ts_config.authorization, ts_config.api_key)
            get_howtofix_res = callAPI2(howtofix_url, 'GET', ts_config.api_key, ts_config.username, ts_config.service_key)
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

            url = '%s/api/v2/issues?apiKey=%s' % (ts_config.backlog.url, ts_config.backlog.api_key)
            # projectId=97197&summary=$Title+$VulnerabilityRule&issueTypeId=456121&priorityId=3&description=$Message
            #payload = {'projectId': json_data['project'], 'summary': json_data['vulnerability_rule']}
            data = {
                'projectId': ts_config.backlog.project_id,
                'summary': summary,
                'issueTypeId': ts_config.backlog.issuetype_id,
                'priorityId': ts_config.backlog.priority_id,
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
            config_name = json_data.get('config_name')
            if config_name:
                ts_config = Integration.objects.get(name=config_name)
            else:
                ts_config = Integration.objects.first()
            lib_name = m.group(1)
            org_id = m.group(2)
            app_id = m.group(5)
            lib_lang = m.group(3)
            lib_id = m.group(4)
            teamserver_url = ts_config.url
            url = '%s/api/ng/%s/libraries/%s/%s?expand=vulns' % (teamserver_url, org_id, lib_lang, lib_id)
            #res = callAPI(url, 'GET', ts_config.authorization, ts_config.api_key)
            res = callAPI2(url, 'GET', ts_config.api_key, ts_config.username, ts_config.service_key)
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

            url = '%s/api/v2/issues?apiKey=%s' % (ts_config.backlog.url, ts_config.backlog.api_key)
            data = {
                'projectId': ts_config.backlog.project_id,
                'summary': summary,
                'issueTypeId': ts_config.backlog.issuetype_id,
                'priorityId': ts_config.backlog.priority_id,
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
def hook(request):
    if request.method == 'POST':
        json_data = json.loads(request.body)
        if json_data['event_type'] == 'TEST_CONNECTION':
            integration_name = json_data.get('integration_name')
            print(integration_name)
            if integration_name:
                if not Integration.objects.filter(name=integration_name).exists():
                    return HttpResponse(status=404)
            else:
                return HttpResponse(status=404)
            return HttpResponse(status=200)
        elif json_data['event_type'] == 'NEW_VULNERABILITY':
            print(_('event_new_vulnerability'))
            #print(json_data['description'])
            integration_name = json_data.get('integration_name')
            if integration_name:
                if not Integration.objects.filter(name=integration_name).exists():
                    return HttpResponse(status=404)
            else:
                return HttpResponse(status=404)
            ts_config = Integration.objects.get(name=integration_name)
            app_name = json_data['application_name']
            org_id = json_data['organization_id']
            app_id = json_data['application_id']
            vul_id = json_data['vulnerability_id']
            self_url = ''
            r = re.compile(".+\((.+" + vul_id + ")\)")
            m = r.search(json_data['description'])
            if m is not None:
                self_url = m.group(1)

            teamserver_url = ts_config.url
            url = '%s/api/ng/%s/traces/%s/trace/%s?expand=servers,application' % (teamserver_url, org_id, app_id, vul_id)
            #res = callAPI(url, 'GET', ts_config.authorization, ts_config.api_key)
            res = callAPI2(url, 'GET', ts_config.api_key, ts_config.username, ts_config.service_key)
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
            #get_story_res = callAPI(story_url, 'GET', ts_config.authorization, ts_config.api_key)
            get_story_res = callAPI2(story_url, 'GET', ts_config.api_key, ts_config.username, ts_config.service_key)
            story_json = get_story_res.json()
            chapters = []
            for chapter in story_json['story']['chapters']:
                chapters.append('%s\n' % chapter['introText'])
                if chapter['type'] == 'properties':
                    for key, value in chapter['properties']:
                        chapters.append('%s\n' % key)
                        chapters.append('{{#xxxxBlock}}%s{{/xxxxBlock}}\n' % value['value'])
                elif chapter['type'] in ['configuration', 'location', 'recreation', 'dataflow', 'source']:
                    chapters.append('{{#xxxxBlock}}%s{{/xxxxBlock}}\n' % chapter['body'])
            story = story_json['story']['risk']['formattedText']
            # How to fix
            #get_howtofix_res = callAPI(howtofix_url, 'GET', ts_config.authorization, ts_config.api_key)
            get_howtofix_res = callAPI2(howtofix_url, 'GET', ts_config.api_key, ts_config.username, ts_config.service_key)
            howtofix_json = get_howtofix_res.json()
            howtofix = howtofix_json['recommendation']['formattedText']

            deco_mae = "## "
            deco_ato = ""
            description = []
            description.append('%s%s%s\n' % (deco_mae, '何が起こったか？', deco_ato))
            description.append('%s\n\n' %  (convertMustache(''.join(chapters))))
            description.append('%s%s%s\n' % (deco_mae, 'どんなリスクであるか？', deco_ato))
            description.append('%s\n\n' %  (convertMustache(story)))
            description.append('%s%s%s\n' % (deco_mae, '修正方法', deco_ato))
            description.append('%s\n\n' %  (convertMustache(howtofix)))
            description.append('%s%s%s\n' % (deco_mae, '脆弱性URL', deco_ato))
            description.append(self_url)

            priority_id = json_data['priorityId']
            url = '%s/api/v4/projects/%s/issues' % (ts_config.gitlab.url, ts_config.gitlab.project_id)
            data = {
                'title': summary,
                'labels': ts_config.gitlab.vul_labels,
                'description': ''.join(description),
            }   
            headers = {
                'Content-Type': 'application/json',
                'PRIVATE-TOKEN': ts_config.gitlab.access_token
            }
            res = requests.post(url, json=data, headers=headers)
            print(res.status_code)
            if res.status_code == requests.codes.created:
                mapping = GitlabMapping(gitlab=ts_config.gitlab, contrast_org_id=org_id, contrast_app_id=app_id, contrast_vul_id=vul_id)
                mapping.gitlab_issue_id = res.json()['id']
                mapping.save()
            return HttpResponse(status=200)
        elif json_data['event_type'] == 'VULNERABILITY_CHANGESTATUS_OPEN' or json_data['event_type'] == 'VULNERABILITY_CHANGESTATUS_CLOSED':
            #print(_('event_vulnerability_changestatus'))
            integration_name = json_data.get('integration_name')
            print(integration_name)
            if integration_name:
                if not Integration.objects.filter(name=integration_name).exists():
                    return HttpResponse(status=404)
            else:
                return HttpResponse(status=404)
            ts_config = Integration.objects.get(name=integration_name)
            status = json_data['status']
            vul_id = json_data['vulnerability_id']
            teamserver_url = ts_config.url
            if vul_id is None:
                print(_('problem_with_customfield'))
                return HttpResponse(status=200)
            print(status)
            if status in ['Reported', 'Suspicious', 'Confirmed']:
                gitlab_mapping = GitlabMapping.objects.filter(contrast_vul_id=vul_id).first()
                if gitlab_mapping is None:
                    return HttpResponse(status=200)
                url = '%s/api/v4/projects/%s/issues/%d?state_event=reopen' % (ts_config.gitlab.url, ts_config.gitlab.project_id, gitlab_mapping.gitlab_issue_id)
                headers = {
                    'Content-Type': 'application/json',
                    'PRIVATE-TOKEN': ts_config.gitlab.access_token
                }
                res = requests.put(url, headers=headers)
                print(res.status_code)
                return HttpResponse(status=200)
            elif status in ['NotAProblem', 'Not a Problem', 'Remediated', 'Fixed']:
                gitlab_mapping = GitlabMapping.objects.filter(contrast_vul_id=vul_id).first()
                if gitlab_mapping is None:
                    return HttpResponse(status=200)
                url = '%s/api/v4/projects/%s/issues/%d?state_event=close' % (ts_config.gitlab.url, ts_config.gitlab.project_id, gitlab_mapping.gitlab_issue_id)
                headers = {
                    'Content-Type': 'application/json',
                    'PRIVATE-TOKEN': ts_config.gitlab.access_token
                }
                res = requests.put(url, headers=headers)
                print(res.status_code)
                return HttpResponse(status=200)
            else:
                return HttpResponse(status=200)
        elif json_data['event_type'] == 'NEW_VULNERABLE_LIBRARY':
            print(_('event_new_vulnerable_library'))
            config_name = json_data.get('config_name')
            if config_name:
                ts_config = Integration.objects.get(name=config_name)
            else:
                ts_config = Integration.objects.first()
            org_id = json_data['organization_id']
            app_id = json_data['application_id']
            r = re.compile("index.html#\/" + org_id + "\/libraries\/(.+)\/([a-z0-9]+)\)")
            m = r.search(json_data['description'])
            if m is None:
                return HttpResponse(status=200)
            lib_lang = m.group(1)
            lib_id = m.group(2)
            teamserver_url = ts_config.url
            url = '%s/api/ng/%s/libraries/%s/%s?expand=vulns' % (teamserver_url, org_id, lib_lang, lib_id)
            res = callAPI2(url, 'GET', ts_config.api_key, ts_config.username, ts_config.service_key)
            lib_json = res.json()
            lib_name = lib_json['library']['file_name']
            file_version = lib_json['library']['file_version']
            latest_version = lib_json['library']['latest_version']
            classes_used = lib_json['library']['classes_used']
            class_count = lib_json['library']['class_count']
            cve_list = []
            for c_link in lib_json['library']['vulns']:
                cve_list.append(c_link['name'])
            r = re.compile(".+\((.+" + lib_id + ")\)")
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

            priority_id = json_data['priorityId']
            url = '%s/api/v4/projects/%s/issues' % (ts_config.gitlab.url, ts_config.gitlab.project_id)
            data = {
                'title': summary,
                'labels': ts_config.gitlab.lib_labels,
                'description': ''.join(description),
            }   
            headers = {
                'Content-Type': 'application/json',
                'PRIVATE-TOKEN': ts_config.gitlab.access_token
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
def vote3(request):
    if request.method == 'POST':
        json_data = json.loads(request.body)
        if json_data['event_type'] == 'TEST_CONNECTION':
            integration_name = json_data.get('integration_name')
            if integration_name:
                if not Integration.objects.filter(name=integration_name).exists():
                    return HttpResponse(status=404)
            else:
                return HttpResponse(status=404)
            return HttpResponse(status=200)
        elif json_data['event_type'] == 'NEW_VULNERABILITY':
            print(json_data['description'])
            integration_name = json_data.get('integration_name')
            if integration_name:
                if not Integration.objects.filter(name=integration_name).exists():
                    return HttpResponse(status=404)
            else:
                return HttpResponse(status=404)
            ts_config = Integration.objects.get(name=integration_name)
            app_name = json_data['application_name']
            org_id = json_data['organization_id']
            app_id = json_data['application_id']
            vul_id = json_data['vulnerability_id']
            self_url = ''
            r = re.compile(".+\((.+" + vul_id + ")\)")
            m = r.search(json_data['description'])
            if m is not None:
                self_url = m.group(1)

            teamserver_url = ts_config.url
            url = '%s/api/ng/%s/traces/%s/trace/%s?expand=servers,application' % (teamserver_url, org_id, app_id, vul_id)
            #res = callAPI(url, 'GET', ts_config.authorization, ts_config.api_key)
            res = callAPI2(url, 'GET', ts_config.api_key, ts_config.username, ts_config.service_key)
            vuln_json = res.json()
            summary = '[%s] %s' % (app_name, vuln_json['trace']['title'])

            deco_mae = "## "
            deco_ato = ""
            description = []
            description.append('環境　　　　　　: %s\n' % (vuln_json['trace']['servers'][0]['environment']))
            description.append('アプリケーション: <%s|%s>\n' % (self_url.replace('/vulns/' + vul_id, ''), app_name))
            description.append('重大度　　　　　: %s\n' % (vuln_json['trace']['severity']))
            description.append('脆弱性　　　　　: <%s|%s>\n' % (self_url, vuln_json['trace']['title']))

            priority_id = json_data['priorityId']
            url = '%s' % (ts_config.googlechat.webhook)
            data = {
                "text": ''.join(description),
            }   
            headers = {
                'Content-Type': 'application/json',
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
            config_name = json_data.get('config_name')
            if config_name:
                ts_config = Integration.objects.get(name=config_name)
            else:
                ts_config = Integration.objects.first()
            lib_name = m.group(1)
            org_id = m.group(2)
            app_id = m.group(5)
            lib_lang = m.group(3)
            lib_id = m.group(4)
            teamserver_url = ts_config.url
            url = '%s/api/ng/%s/libraries/%s/%s?expand=vulns' % (teamserver_url, org_id, lib_lang, lib_id)
            #res = callAPI(url, 'GET', ts_config.authorization, ts_config.api_key)
            res = callAPI2(url, 'GET', ts_config.api_key, ts_config.username, ts_config.service_key)
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

            priority_id = json_data['priorityId']
            url = '%s/api/v4/projects/%s/issues' % (ts_config.gitlab.url, ts_config.gitlab.project_id)
            data = {
                'title': summary,
                'labels': ts_config.gitlab.labels,
                'description': ''.join(description),
            }   
            headers = {
                'Content-Type': 'application/json',
                'PRIVATE-TOKEN': ts_config.gitlab.access_token
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

