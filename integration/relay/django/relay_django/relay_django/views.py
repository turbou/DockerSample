from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from django.http import HttpResponse
from integration.models import Integration
from application.models import Backlog, BacklogVul, BacklogNote, BacklogLib
from application.models import Gitlab, GitlabVul, GitlabNote, GitlabLib
from rest_framework.decorators import api_view, permission_classes, authentication_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework_jwt.authentication import JSONWebTokenAuthentication, BaseJSONWebTokenAuthentication
from django.utils.translation import gettext_lazy as _

from datetime import datetime as dt
import json
import requests
import re
import base64
import html

def callAPI(url, method, api_key, username, service_key, data=None):
    authorization = base64.b64encode(('%s:%s' % (username, service_key)).encode('utf-8'))
    headers = {
        'Authorization': authorization,
        'API-Key': api_key,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
    }
    if method == 'GET':
        res = requests.get(url, headers=headers)
    elif method == 'POST':
        res = requests.post(url, data=data, headers=headers)
    elif method == 'PUT':
        res = requests.put(url, data=data, headers=headers)
    return res

def convertMustache(old_str):
    # Link
    new_str = re.sub(r'{{#link}}(.+?)\$\$LINK_DELIM\$\$(.+?){{\/link}}', r'[\2](\1)', old_str)
    # CodeBlock
    new_str = re.sub(r'{{#[A-Za-z]+Block}}', '~~~\n', new_str)
    new_str = re.sub(r'{{\/[A-Za-z]+Block}}', '\n~~~', new_str)
    # Header
    new_str = new_str.replace('{{#header}}', '### ').replace('{{\/header}}', '')
    # List
    new_str = new_str.replace('{{#listElement}}', '* ').replace('{{\/listElement}}', '')
    # Table
    r = re.compile('({{#tableRowX}}[\s]*.+[\s]*{{/tableRowX}})')
    while True:
      tbl_bgn_idx = new_str.find('{{#table}}')
      tbl_end_idx = new_str.find('{{/table}}')
      print(tbl_bgn_idx, tbl_end_idx)
      if tbl_bgn_idx < 0 or tbl_end_idx < 0:
        break
      else:
        tbl_str = new_str[tbl_bgn_idx:tbl_end_idx + 10] # 10は{{/table}}の文字数
        tbl_str = re.sub(r'({{#tableRow}}[\s]*({{#tableHeaderRow}}.+{{/tableHeaderRow}})[\s]*{{/tableRow}})', '\\1' + "\n{{#tableRowX}}" + '\\2' + '{{/tableRowX}}', tbl_str)
        m = r.search(tbl_str)
        if m is not None:
          replace_str = m.group(1).replace('tableHeaderRow', 'tableHeaderRowX')
          tbl_str = re.sub(r'{{#tableRowX}}[\s]*.+[\s]*{{/tableRowX}}', replace_str, tbl_str)
          tbl_str = re.sub(r'({{#tableHeaderRowX}})(.+?)({{/tableHeaderRowX}})', '\\1---\\3', tbl_str)
        tbl_str = re.sub(r'[ \t]*{{#tableRow}}[\s]*{{#tableHeaderRow}}', '|', tbl_str)
        tbl_str = re.sub(r'{{/tableHeaderRow}}[\s]*', '|', tbl_str)
        tbl_str = re.sub(r'[ \t]*{{#tableRowX}}[\s]*{{#tableHeaderRowX}}', '|', tbl_str)
        tbl_str = re.sub(r'{{/tableHeaderRowX}}[\s]*', '|', tbl_str)
        tbl_str = re.sub(r'[ \t]*{{#tableRow}}[\s]*{{#tableCell}}', '|', tbl_str)
        tbl_str = re.sub(r'{{/tableCell}}[\s]*', '|', tbl_str)
        tbl_str = re.sub(r'[ \t]*{{#badTableRow}}[\s]*{{#tableCell}}', '\n|', tbl_str)
        tbl_str = re.sub(r'{{/tableCell}}[\s]*', '|', tbl_str)
        tbl_str = re.sub(r'{{{nl}}}', '<br>', tbl_str)
        tbl_str = re.sub(r'{{(#|/)[A-Za-z]+}}', '', tbl_str) # ここで残ったmustacheを全削除
        new_str = '%s%s%s' % (new_str[:tbl_bgn_idx], tbl_str, new_str[tbl_end_idx + 10:])

    # New line
    new_str = re.sub(r'{{{nl}}}', '\n', new_str)
    # Other
    new_str = re.sub(r'{{(#|\/)[A-Za-z]+}}', '', new_str)
    # Comment
    new_str = re.sub(r'{{!.+}}', '', new_str)
    # <, >
    new_str = new_str.replace('&lt;', '<').replace('&gt;', '>').replace('&nbsp;', ' ')
    # Quot
    new_str = new_str.replace('&quot;', '"')
    # Tab
    new_str = new_str.replace('\t', '    ')
    # Character Reference
    new_str = re.sub(r'&#[^;]+;', '', new_str)
    return new_str

def syncCommentFromContrast(ts_config, org_id, app_id, vul_id):
    print('syncCommentFromContrast!!')
    gitlab_mapping = GitlabVul.objects.filter(contrast_vul_id=vul_id).first()
    if gitlab_mapping is None:
        return HttpResponse(status=200)
    # TeamServer側のコメントすべて取得
    teamserver_url = ts_config.url
    url = '%s/api/ng/%s/applications/%s/traces/%s/notes?expand=skip_links' % (teamserver_url, org_id, app_id, vul_id)
    res = callAPI(url, 'GET', ts_config.api_key, ts_config.username, ts_config.service_key)
    notes_json = res.json()
    #print(notes_json)
    r = re.compile("\(by .+\)")
    headers = {
        'Content-Type': 'application/json',
        'PRIVATE-TOKEN': ts_config.gitlab.access_token
    }
    for c_note in notes_json['notes']:
        if c_note['creator_uid'] == ts_config.username:
            continue
        if GitlabNote.objects.filter(contrast_note_id=c_note['id']).exists():
            continue
        creator = '(by ' + c_note['creator'] + ')'
        m = r.search(html.unescape(c_note['note']))
        if m is not None:
            creator = ''
        old_status_str = ''
        new_status_str = ''
        status_change_reason_str = ''
        if 'properties' in c_note:
            for c_prop in c_note['properties']:
              if c_prop['name'] == 'status.change.previous.status':
                pass
                #status_obj = ContrastUtil.get_redmine_status(c_prop['value'])
                #unless status_obj.nil?
                #  old_status_str = status_obj.name
                #end
              elif c_prop['name'] == 'status.change.status':
                pass
                #status_obj = ContrastUtil.get_redmine_status(c_prop['value'])
                #unless status_obj.nil?
                #  new_status_str = status_obj.name
                #end
              elif c_prop['name'] == 'status.change.substatus' and len(c_prop['value']) > 0:
                status_change_reason_str = '問題無しへの変更理由: %s\n' % c_prop['value']
        note_str = html.unescape(status_change_reason_str + c_note['note']) + creator
        url = '%s/api/v4/projects/%s/issues/%d/notes' % (ts_config.gitlab.url, ts_config.gitlab.project_id, gitlab_mapping.issue_id)
        created_at = dt.fromtimestamp(c_note['creation'] / 1000)
        data = {
            'body': note_str,
            'created_at': created_at.isoformat() # required Administrator(project or group owner) only.
        }
        res = requests.post(url, json=data, headers=headers)
        #print(res.status_code)
        #print('oyoyo!! ', res.text)
        if res.status_code == requests.codes.created:
            gitlab_note = GitlabNote(vul=gitlab_mapping, note=note_str, creator=creator, contrast_note_id=c_note['id'])
            gitlab_note.gitlab_note_id = res.json()['id']
            gitlab_note.created_at = created_at
            gitlab_note.save()

def syncCommentFromGitlab(ts_config, org_id, app_id, vul_id):
    print('syncCommentGitlab!!')
    # Gitlab側のコメントをすべて取得
    gitlab_mapping = GitlabVul.objects.filter(contrast_vul_id=vul_id).first()
    if gitlab_mapping is None:
        return HttpResponse(status=200)
    url = '%s/api/v4/projects/%s/issues/%d/notes' % (ts_config.gitlab.url, ts_config.gitlab.project_id, gitlab_mapping.issue_id)
    headers = {
        'Content-Type': 'application/json',
        'PRIVATE-TOKEN': ts_config.gitlab.access_token
    }
    res = requests.get(url, headers=headers)
    issue_notes_json = res.json()
    #print(issue_notes_json)
    teamserver_url = ts_config.url
    url = '%s/api/ng/%s/applications/%s/traces/%s/notes?expand=skip_links' % (teamserver_url, org_id, app_id, vul_id)
    for issue_note in issue_notes_json:
        if GitlabNote.objects.filter(gitlab_note_id=issue_note['id']).exists():
            continue
        #print(issue_note['author']['name'], issue_note['created_at'], issue_note['body'])
        data_dict = {'note': issue_note['body']}
        res = callAPI(url, 'POST', ts_config.api_key, ts_config.username, ts_config.service_key, json.dumps(data_dict))
        #print(res.status_code)
        #print('buhihi!! ', res.text)
        #print(res.json())
        if res.status_code == requests.codes.ok:
            res_json = res.json()
            #print(res_json['note']['creation'])
            gitlab_note = GitlabNote(vul=gitlab_mapping, note=issue_note['body'], creator=issue_note['author']['name'], contrast_note_id=res_json['note']['id'])
            gitlab_note.gitlab_note_id = issue_note['id']
            created_at = dt.fromtimestamp(res_json['note']['creation'] / 1000)
            gitlab_note.created_at = created_at
            gitlab_note.save()

def syncComment(ts_config, org_id, app_id, vul_id, kubun=0):
    print('syncComment!!')
    # まずはTeamServer側のコメントすべて取得
    teamserver_url = ts_config.url
    url = '%s/api/ng/%s/applications/%s/traces/%s/notes?expand=skip_links' % (teamserver_url, org_id, app_id, vul_id)
    res = callAPI(url, 'GET', ts_config.api_key, ts_config.username, ts_config.service_key)
    notes_json = res.json()
    #print(notes_json)
    note_ids = []
    for note in notes_json['notes']:
        note_ids.append(note['id'])
        #print(note['creator'], note['creation'], html.unescape(note['note']))

    # 次にGitlab側のコメントをすべて取得
    gitlab_mapping = GitlabVul.objects.filter(contrast_vul_id=vul_id).first()
    if gitlab_mapping is None:
        return HttpResponse(status=200)
    url = '%s/api/v4/projects/%s/issues/%d/notes' % (ts_config.gitlab.url, ts_config.gitlab.project_id, gitlab_mapping.issue_id)
    headers = {
        'Content-Type': 'application/json',
        'PRIVATE-TOKEN': ts_config.gitlab.access_token
    }
    res = requests.get(url, headers=headers)
    issue_notes_json = res.json()
    #print(issue_notes_json)
    issue_note_ids = []
    for issue_note in issue_notes_json:
        issue_note_ids.append(issue_note['id'])
        #print(issue_note['author']['name'], issue_note['created_at'], issue_note['body'])

    print(note_ids)
    print(issue_note_ids)

    for issue_note in issue_notes_json:
        url = '%s/api/v4/projects/%s/issues/%d/notes/%d' % (ts_config.gitlab.url, ts_config.gitlab.project_id, gitlab_mapping.issue_id, issue_note['id'])
        res = requests.delete(url, headers=headers)
        print(res.status_code)

    r = re.compile("\(by .+\)")
    for c_note in notes_json['notes']:
        creator = '(by ' + c_note['creator'] + ')'
        m = r.search(html.unescape(c_note['note']))
        if m is not None:
            creator = ''
        old_status_str = ''
        new_status_str = ''
        status_change_reason_str = ''
        if 'properties' in c_note:
            for c_prop in c_note['properties']:
              if c_prop['name'] == 'status.change.previous.status':
                pass
                #status_obj = ContrastUtil.get_redmine_status(c_prop['value'])
                #unless status_obj.nil?
                #  old_status_str = status_obj.name
                #end
              elif c_prop['name'] == 'status.change.status':
                pass
                #status_obj = ContrastUtil.get_redmine_status(c_prop['value'])
                #unless status_obj.nil?
                #  new_status_str = status_obj.name
                #end
              elif c_prop['name'] == 'status.change.substatus' and len(c_prop['value']) > 0:
                status_change_reason_str = '問題無しへの変更理由: %s\n' % c_prop['value']
        note_str = html.unescape(status_change_reason_str + c_note['note']) + creator
        url = '%s/api/v4/projects/%s/issues/%d/notes' % (ts_config.gitlab.url, ts_config.gitlab.project_id, gitlab_mapping.issue_id)
        created_at = dt.fromtimestamp(c_note['creation'] / 1000).isoformat()
        data = {
            'body': note_str,
            'created_at': created_at # required Administrator(project or group owner) only.
        }
        res = requests.post(url, json=data, headers=headers)
        print('oyoyo!! ', res.text)

class JSONWebTokenAuthenticationBacklog(BaseJSONWebTokenAuthentication):
    def get_jwt_value(self, request):
         return request.query_params.get('token')

STATUSES = [ 
    'status_reported',
    'status_suspicious',
    'status_confirmed',
    'status_notaproblem',
    'status_remediated',
    'status_fixed',
]

@api_view(['GET', 'POST'])
@permission_classes((IsAuthenticated, ))
@authentication_classes((JSONWebTokenAuthenticationBacklog,))
def backlog(request):
    print('backlog!!')
    json_data = json.loads(request.body)
    #print(json_data)

    issue_id = None
    status_id = None
    for change in json_data['content']['changes']:
        if change['field'] == 'status':
            status_id = change['new_value']
    if status_id is None:
        return HttpResponse(status=200)

    # 一括操作か個別操作かの判定
    issue_id_list = []
    if 'tx_id' in json_data['content']: # 一括操作
        for issue in json_data['content']['link']:
            issue_id_list.append(issue['id'])
    elif 'id' in json_data['content']:  # 個別操作
        issue_id_list.append(json_data['content']['id'])
    else:
        return HttpResponse(status=200)

    for issue_id in issue_id_list:
        backlog_mapping = BacklogVul.objects.filter(issue_id=issue_id).first()
        if backlog_mapping is None:
            continue
        ts_config = backlog_mapping.backlog.integrations.first()
        target_status = None
        target_status_set = set()
        for status in STATUSES:
            sts_id = getattr(backlog_mapping.backlog, '%s_id' % status)
            if status_id == sts_id:
                target_status_set.add(status)
        if len(target_status_set) == 1:
            target_status = list(target_status_set)[0]
        elif len(target_status_set) > 1:
            for status2 in target_status_set:
                if getattr(backlog_mapping.backlog, '%s_priority' % status2):
                    target_status = status2
                    break
        else:
            continue
        contrast_status = None
        if target_status == 'tatus_reported':
            contrast_status = 'Reported'
        elif target_status == 'status_suspicious':
            contrast_status = 'Suspicious'
        elif target_status == 'status_confirmed':
            contrast_status = 'Confirmed'
        elif target_status == 'status_notaproblem':
            contrast_status = 'NotAProblem'
        elif target_status == 'status_remediated':
            contrast_status = 'Remediated'
        elif target_status == 'status_fixed':
            contrast_status = 'Fixed'
        teamserver_url = ts_config.url
        url = '%s/api/ng/%s/orgtraces/mark' % (teamserver_url, backlog_mapping.contrast_org_id)
        data_dict = {'traces': [backlog_mapping.contrast_vul_id], 'status': contrast_status, 'note': 'status changed by Gitlab.'}
        res = callAPI(url, 'PUT', ts_config.api_key, ts_config.username, ts_config.service_key, json.dumps(data_dict))
        print(res.status_code)
    return HttpResponse(status=200)

class JSONWebTokenAuthenticationGitlab(BaseJSONWebTokenAuthentication):
    def get_jwt_value(self, request):
         return request.headers.get('X-Gitlab-Token')

@api_view(['GET', 'POST'])
@permission_classes((IsAuthenticated, ))
@authentication_classes((JSONWebTokenAuthenticationGitlab,))
def gitlab(request):
    print('gitlab!!')
    json_data = json.loads(request.body)
    #print(json_data)
    if not 'event_type' in json_data:
        return HttpResponse(status=200)
    if not json_data['event_type'] in ['issue', 'note']:
        return HttpResponse(status=200)
    #print(json_data['event_type'])

    if json_data['event_type'] == 'note':
        #print(json_data['issue']['iid'])
        gitlab_mapping = GitlabVul.objects.filter(issue_id=json_data['issue']['iid']).first()
        if gitlab_mapping is None:
            return HttpResponse(status=200)
        if json_data['user']['username'] == gitlab_mapping.gitlab.report_username: # 無限ループ止め
            return HttpResponse(status=200)
        ts_config = gitlab_mapping.gitlab.integrations.first()
        syncCommentFromGitlab(ts_config, gitlab_mapping.contrast_org_id, gitlab_mapping.contrast_app_id, gitlab_mapping.contrast_vul_id)
        return HttpResponse(status=200)
    elif json_data['event_type'] == 'issue':
        if not 'action' in json_data['object_attributes']:
            return HttpResponse(status=200)
        #print(json_data)
        #print(json_data['object_attributes']['action'])
        if json_data['object_attributes']['action'] == 'open':
            return HttpResponse(status=200)
        #print(json_data['object_attributes'].keys())
        #print(json_data['object_attributes']['iid'])
        #print(json_data['object_attributes']['action'])
        gitlab_mapping = GitlabVul.objects.filter(issue_id=json_data['object_attributes']['iid']).first()
        if gitlab_mapping is None:
            return HttpResponse(status=200)
        #print(gitlab_mapping.contrast_org_id)
        if json_data['user']['username'] == gitlab_mapping.gitlab.report_username: # 無限ループ止め
            return HttpResponse(status=200)
    
        if json_data['object_attributes']['action'] == 'close':
            ts_config = gitlab_mapping.gitlab.integrations.first()
            teamserver_url = ts_config.url
            url = '%s/api/ng/%s/orgtraces/mark' % (teamserver_url, gitlab_mapping.contrast_org_id)
            data_dict = {'traces': [gitlab_mapping.contrast_vul_id], 'status': 'Remediated', 'note': 'closed by Gitlab.'}
            res = callAPI(url, 'PUT', ts_config.api_key, ts_config.username, ts_config.service_key, json.dumps(data_dict))
            #print(res.text)
        elif json_data['object_attributes']['action'] == 'reopen':
            ts_config = gitlab_mapping.gitlab.integrations.first()
            teamserver_url = ts_config.url
            url = '%s/api/ng/%s/orgtraces/mark' % (teamserver_url, gitlab_mapping.contrast_org_id)
            data_dict = {'traces': [gitlab_mapping.contrast_vul_id], 'status': 'Reported'}
            res = callAPI(url, 'PUT', ts_config.api_key, ts_config.username, ts_config.service_key, json.dumps(data_dict))
            #print(res.text)
    else:
        return HttpResponse(status=200)
    return HttpResponse(status=200)

@require_http_methods(["GET", "POST", "PUT"])
@csrf_exempt
def hook(request):
    if request.method == 'POST':
        json_data = json.loads(request.body)
        event_type = json_data['event_type']
        if event_type == 'TEST_CONNECTION':
            integration_name = json_data.get('integration_name')
            print(integration_name)
            if integration_name:
                if not Integration.objects.filter(name=integration_name).exists():
                    return HttpResponse(status=404)
            else:
                return HttpResponse(status=404)
            return HttpResponse(status=200)
        elif event_type == 'NEW_VULNERABILITY' or event_type == 'VULNERABILITY_DUPLICATE':
            if event_type == 'NEW_VULNERABILITY':
                print(_('event_new_vulnerability'))
            else:
                print(_('event_dup_vulnerability'))
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
            r = re.compile(".+\((.+/vulns/[A-Z0-9\-]{19})\)")
            m = r.search(json_data['description'])
            if m is not None:
                self_url = m.group(1)

            teamserver_url = ts_config.url
            url = '%s/api/ng/%s/traces/%s/trace/%s?expand=servers,application' % (teamserver_url, org_id, app_id, vul_id)
            res = callAPI(url, 'GET', ts_config.api_key, ts_config.username, ts_config.service_key)
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
            get_story_res = callAPI(story_url, 'GET', ts_config.api_key, ts_config.username, ts_config.service_key)
            story_json = get_story_res.json()
            chapters = []
            for chapter in story_json['story']['chapters']:
                chapters.append('%s\n\n' % chapter['introText'])
                if chapter['type'] == 'properties':
                    for key in chapter['properties']:
                        chapters.append('%s\n\n' % key)
                        value = chapter['properties'][key]
                        if value['value'].startswith('{{#table}}'):
                            chapters.append('\n%s\n' % value['value'])
                        else:
                            chapters.append('{{#xxxxBlock}}%s{{/xxxxBlock}}\n' % value['value'])
                elif chapter['type'] in ['configuration', 'location', 'recreation', 'dataflow', 'source']:
                    chapters.append('{{#xxxxBlock}}%s{{/xxxxBlock}}\n' % chapter['body'])
            story = story_json['story']['risk']['formattedText']
            # How to fix
            get_howtofix_res = callAPI(howtofix_url, 'GET', ts_config.api_key, ts_config.username, ts_config.service_key)
            howtofix_json = get_howtofix_res.json()
            howtofix = howtofix_json['recommendation']['formattedText']


            # ---------- Backlog ---------- #
            if ts_config.backlog:
                headers = {
                    'Content-Type': 'application/json'
                }
                deco_mae = '## '
                deco_ato = ''
                description = []
                description.append('%s%s%s\n' % (deco_mae, '何が起こったか？', deco_ato))
                description.append('%s\n\n' %  (convertMustache(''.join(chapters))))
                description.append('%s%s%s\n' % (deco_mae, 'どんなリスクであるか？', deco_ato))
                description.append('%s\n\n' %  (convertMustache(story)))
                description.append('%s%s%s\n' % (deco_mae, '修正方法', deco_ato))
                description.append('%s\n\n' %  (convertMustache(howtofix)))
                description.append('%s%s%s\n' % (deco_mae, '脆弱性URL', deco_ato))
                description.append(self_url)

                severity = vuln_json['trace']['severity']
                priority_id = None
                if severity == 'Critical':
                    priority_id = ts_config.backlog.priority_critical_id
                elif severity == 'High':
                    priority_id = ts_config.backlog.priority_high_id
                elif severity == 'Medium':
                    priority_id = ts_config.backlog.priority_medium_id
                elif severity == 'Low':
                    priority_id = ts_config.backlog.priority_low_id
                elif severity == 'Note':
                    priority_id = ts_config.backlog.priority_note_id

                if not BacklogVul.objects.filter(contrast_vul_id=vul_id).exists():
                    url = '%s/api/v2/issues?apiKey=%s' % (ts_config.backlog.url, ts_config.backlog.api_key)
                    data = {
                        'projectId': ts_config.backlog.project_id,
                        'summary': summary,
                        'issueTypeId': ts_config.backlog.issuetype_id,
                        'priorityId': priority_id,
                        'description': ''.join(description),
                    }   
                    res = requests.post(url, json=data, headers=headers)
                    print(res.status_code)
                    if res.status_code == requests.codes.created: # 201
                        mapping = BacklogVul(backlog=ts_config.backlog, contrast_org_id=org_id, contrast_app_id=app_id, contrast_vul_id=vul_id)
                        mapping.issue_id = res.json()['id']
                        mapping.save()
                elif event_type == 'VULNERABILITY_DUPLICATE':
                    backlog_mapping = BacklogVul.objects.filter(contrast_vul_id=vul_id).first()
                    # /api/v2/issues/:issueIdOrKey 
                    url = '%s/api/v2/issues/%s?apiKey=%s' % (ts_config.backlog.url, backlog_mapping.issue_id, ts_config.backlog.api_key)
                    data = {
                        'description': ''.join(description),
                    }   
                    res = requests.patch(url, json=data, headers=headers)
                    print(res.status_code)

            # ---------- Gitlab ---------- #
            if ts_config.gitlab:
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
                #print(res.status_code)
                if res.status_code == requests.codes.created: # 201
                    mapping = GitlabVul(gitlab=ts_config.gitlab, contrast_org_id=org_id, contrast_app_id=app_id, contrast_vul_id=vul_id)
                    mapping.issue_id = res.json()['id']
                    mapping.save()

            # ---------- Google Chat ---------- #
            if ts_config.googlechat:
                deco_mae = "## " 
                deco_ato = ""
                description = []
                description.append('環境　　　　　　: %s\n' % (vuln_json['trace']['servers'][0]['environment']))
                description.append('アプリケーション: <%s|%s>\n' % (self_url.replace('/vulns/' + vul_id, ''), app_name))
                description.append('重大度　　　　　: %s\n' % (vuln_json['trace']['severity']))
                description.append('脆弱性　　　　　: <%s|%s>\n' % (self_url, vuln_json['trace']['title']))
    
                url = '%s' % (ts_config.googlechat.webhook)
                data = {
                    "text": ''.join(description),
                }       
                headers = {
                    'Content-Type': 'application/json',
                }       
                res = requests.post(url, json=data, headers=headers)
                #print(res.status_code)
                #print(res.json())
                #return HttpResponse(status=200)
    
            return HttpResponse(status=200)
        elif event_type == 'VULNERABILITY_CHANGESTATUS_OPEN' or event_type == 'VULNERABILITY_CHANGESTATUS_CLOSED':
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
            #print(status)
            # ---------- Backlog ---------- #
            if ts_config.backlog:
                status_id = None
                if status in ['Reported', '報告済']:
                    status_id = ts_config.backlog.status_reported_id
                elif status in ['Suspicious', '疑わしい']:
                    status_id = ts_config.backlog.status_suspicious_id
                elif status in ['Confirmed', '確認済']:
                    status_id = ts_config.backlog.status_confirmed_id
                elif status in ['NotAProblem', 'Not a Problem', '問題無し']:
                    status_id = ts_config.backlog.status_notaproblem_id
                elif status in ['Remediated', '修復済']:
                    status_id = ts_config.backlog.status_remediated_id
                elif status in ['Fixed', '修正完了']:
                    status_id = ts_config.backlog.status_fixed_id
                backlog_mapping = BacklogVul.objects.filter(contrast_vul_id=vul_id).first()
                # /api/v2/issues/:issueIdOrKey 
                url = '%s/api/v2/issues/%s?apiKey=%s' % (ts_config.backlog.url, backlog_mapping.issue_id, ts_config.backlog.api_key)
                data = {
                    'statusId': status_id,
                }   
                headers = {
                    'Content-Type': 'application/json'
                }
                res = requests.patch(url, json=data, headers=headers)
                print(res.status_code)
                #print(res.json())
                if res.status_code == requests.codes.ok: # 200
                    pass
            # ---------- Gitlab ---------- #
            if ts_config.gitlab:
                if status in ['Reported', 'Suspicious', 'Confirmed', '報告済', '疑わしい', '確認済']:
                    gitlab_mapping = GitlabVul.objects.filter(contrast_vul_id=vul_id).first()
                    if gitlab_mapping is None:
                        return HttpResponse(status=200)
                    url = '%s/api/v4/projects/%s/issues/%d?state_event=reopen' % (ts_config.gitlab.url, ts_config.gitlab.project_id, gitlab_mapping.issue_id)
                    headers = {
                        'Content-Type': 'application/json',
                        'PRIVATE-TOKEN': ts_config.gitlab.access_token
                    }
                    res = requests.put(url, headers=headers)
                    #print(res.status_code)
                    return HttpResponse(status=200)
                elif status in ['NotAProblem', 'Not a Problem', 'Remediated', 'Fixed', '問題無し', '修復済', '修正完了']:
                    gitlab_mapping = GitlabVul.objects.filter(contrast_vul_id=vul_id).first()
                    if gitlab_mapping is None:
                        return HttpResponse(status=200)
                    url = '%s/api/v4/projects/%s/issues/%d?state_event=close' % (ts_config.gitlab.url, ts_config.gitlab.project_id, gitlab_mapping.issue_id)
                    headers = {
                        'Content-Type': 'application/json',
                        'PRIVATE-TOKEN': ts_config.gitlab.access_token
                    }
                    res = requests.put(url, headers=headers)
                    #print(res.status_code)
                    return HttpResponse(status=200)
                else:
                    return HttpResponse(status=200)
            return HttpResponse(status=200)
        elif event_type == 'NEW_VULNERABILITY_COMMENT':
            print(_('event_new_vulnerability_comment'))
            #print(json_data['description'])
            #print(json_data['vulnerability_id'])
            integration_name = json_data.get('integration_name')
            #print(integration_name)
            if integration_name:
                if not Integration.objects.filter(name=integration_name).exists():
                    return HttpResponse(status=404)
            else:
                return HttpResponse(status=404)
            ts_config = Integration.objects.get(name=integration_name)
            org_id = json_data['organization_id']
            app_id = json_data['application_id']
            vul_id = json_data['vulnerability_id']

            # ---------- Gitlab ---------- #
            if ts_config.gitlab:
                syncCommentFromContrast(ts_config, org_id, app_id, vul_id)
            return HttpResponse(status=200)
        elif event_type == 'NEW_VULNERABLE_LIBRARY':
            print(_('event_new_vulnerable_library'))
            integration_name = json_data.get('integration_name')
            print(integration_name)
            if integration_name:
                if not Integration.objects.filter(name=integration_name).exists():
                    return HttpResponse(status=404)
            else:
                return HttpResponse(status=404)
            ts_config = Integration.objects.get(name=integration_name)
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
            res = callAPI(url, 'GET', ts_config.api_key, ts_config.username, ts_config.service_key)
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

            # ---------- Backlog ---------- #
            if ts_config.backlog:
                summary = lib_name
                # description
                deco_mae = '## '
                deco_ato = ''
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
                priority_id = ts_config.backlog.priority_cvelib_id
                url = '%s/api/v2/issues?apiKey=%s' % (ts_config.backlog.url, ts_config.backlog.api_key)
                data = {
                    'projectId': ts_config.backlog.project_id,
                    'summary': summary,
                    'issueTypeId': ts_config.backlog.issuetype_id,
                    'priorityId': priority_id,
                    'description': ''.join(description),
                }   
                headers = {
                    'Content-Type': 'application/json'
                }
                res = requests.post(url, json=data, headers=headers)
                print(res.status_code)
                #print(res.json())
                if res.status_code == requests.codes.created: # 201
                    mapping = BacklogLib(backlog=ts_config.backlog, contrast_org_id=org_id, contrast_app_id=app_id, contrast_lib_lg=lib_lang, contrast_lib_id=lib_id)
                    mapping.issue_id = res.json()['id']
                    mapping.save()

            # ---------- Gitlab ---------- #
            if ts_config.gitlab:
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
                #print(res.status_code)
                #print(res.json())
                if res.status_code == requests.codes.created:
                    mapping = GitlabLib(gitlab=ts_config.gitlab, contrast_org_id=org_id, contrast_app_id=app_id, contrast_lib_lg=lib_lang, contrast_lib_id=lib_id)
                    mapping.issue_id = res.json()['id']
                    mapping.save()
                    #return HttpResponse(json.dumps({'messages': res.json()}), content_type='application/json', status=200)
                else:
                    pass
                    #return HttpResponse(json.dumps({'messages': res.json()}), content_type='application/json', status=res.status_code)
            return HttpResponse(status=200)
        else:
            return HttpResponse(status=200)
    elif request.method == 'PUT':
        return HttpResponse(status=200)
    return HttpResponse(status=404)

