from django.core.management.base import BaseCommand, CommandError
from django.conf import settings
from application.models import Backlog

import json
import requests

class Command(BaseCommand):
    help = 'Backlogのissueを一括削除します。'

    def add_arguments(self, parser):
        parser.add_argument(
            '--name', dest='name', default=None,
            help='Backlog設定の名前を指定してください。',
        )

    def handle(self, *args, **options):
        name = options.get('name')
        projectid = options.get('projectid')
        if name is None:
            raise CommandError('--name オプションは必須です。')
        backlog = Backlog.objects.get(name=name)
        if backlog is None:
            raise CommandError('%s のBacklog設定が見つかりません。' % name)
        url = '%s/api/v2/issues' % (backlog.url)
        params = {'apiKey': backlog.api_key, 'projectId[]': backlog.project_id, 'count': 100}
        res = requests.get(url, params=params)
        issues_json = res.json()
        del_params = {'apiKey': backlog.api_key}
        for issue in issues_json:
            del_url = '%s/api/v2/issues/%s' % (backlog.url, issue['id'])
            res = requests.delete(del_url, params=del_params)
            print('%s -> %s' % (issue['id'], res.status_code))

