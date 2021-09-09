from celery import shared_task
from celery.utils.log import get_task_logger
from django.core.management import call_command
from application.models import Redmine, RedmineVul, RedmineNote
from redminelib import Redmine as RedmineApi

from relay_django.celery import app

from datetime import datetime as dt
import json
import requests
import re
import base64
import html
import traceback

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

#@shared_task
@app.task
def redmine_sample_task():
    for redmine in Redmine.objects.all():
        redmine_api = RedmineApi(redmine.url, key=redmine.access_key)
        issues = redmine_api.issue.filter(project_id=redmine.project_id, sort='category:desc')
        for issue in issues:
            if RedmineVul.objects.filter(issue_id=issue.id).exists():
                # ステータスの同期
                status = None
                if redmine.status_id_reported == issue.status.id:
                  status = 'Reported'
                elif redmine.status_id_suspicious == issue.status.id:
                  status = 'Suspicious'
                elif redmine.status_id_confirmed == issue.status.id:
                  status = 'Confirmed'
                elif redmine.status_id_notaproblem == issue.status.id:
                  status = 'NotAProblem'
                elif redmine.status_id_remediated == issue.status.id:
                  status = 'Remediated'
                elif redmine.status_id_fixed == issue.status.id:
                  status = 'Fixed'
                print(status)
                if status:
                    mapping = RedmineVul.objects.filter(issue_id=issue.id).first()
                    mapping.status_id = issue.status.id
                    mapping.save()
                    for ts_config in redmine.integrations.all():
                        teamserver_url = ts_config.url
                        #url = sprintf('%s/api/ng/%s/orgtraces/mark', teamserver_url, org_id)
                        #t_data_dict = {"traces" => [vul_id], "status" => status}
                        url = '%s/api/ng/%s/orgtraces/mark' % (teamserver_url, mapping.contrast_org_id)
                        print(url)
                        t_data = {'traces': [mapping.contrast_vul_id], 'status': status, 'note': 'oyoyo'}
                        json_data = json.dumps(t_data).encode('utf-8')
                        print(json_data)
                        res = callAPI(url, 'PUT', ts_config.api_key, ts_config.username, ts_config.service_key, data=json_data)
                        print(res.json())
            # コメントの同期
            for journal in issue.journals:
                #print(journal.id, journal.user, journal.created_on)
                #print(issue.subject, journal.notes)
                print(len(journal.notes))
                print(journal.notes)
                if len(journal.notes) == 0:
                    continue
                if RedmineVul.objects.filter(issue_id=issue.id).exists():
                    mapping = RedmineVul.objects.filter(issue_id=issue.id).first()
                    if RedmineNote.objects.filter(vul=mapping, note_id=journal.id):
                        continue
                    #url = sprintf('%s/api/ng/%s/applications/%s/traces/%s/notes?expand=skip_links', teamserver_url, org_id, app_id, vul_id)
                    #t_data = {"note" => note + " (by " + issue.last_updated_by.name + ")"}.to_json
                    #res, msg = ContrastUtil.callAPI(url: url, method: "POST", data: t_data)
                    for ts_config in redmine.integrations.all():
                        teamserver_url = ts_config.url
                        url = '%s/api/ng/%s/applications/%s/traces/%s/notes?expand=skip_links' % (teamserver_url, mapping.contrast_org_id, mapping.contrast_app_id, mapping.contrast_vul_id)
                        t_data = {'note': '%s (by %s)' % (journal.notes, journal.user)}
                        json_data = json.dumps(t_data).encode('utf-8')
                        res = callAPI(url, 'POST', ts_config.api_key, ts_config.username, ts_config.service_key, data=json_data)
                        print(res.json())
                        res_json = res.json()
                        if res_json['success']:
                            redmine_note = RedmineNote(vul=mapping, note=journal.notes, creator=journal.user, contrast_note_id=res_json['note']['id'], note_id=journal.id)
                            redmine_note.created_at = journal.created_on
                            redmine_note.save()

