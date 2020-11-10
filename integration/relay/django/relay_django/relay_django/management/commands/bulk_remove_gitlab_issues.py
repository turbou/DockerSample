from django.core.management.base import BaseCommand, CommandError
from django.conf import settings
from application.models import Gitlab

import json
import requests

class Command(BaseCommand):
    help = 'Gitlabのissueを一括削除します。'

    def add_arguments(self, parser):
        parser.add_argument(
            '--name', dest='name', default=None,
            help='Gitlab設定の名前を指定してください。',
        )

    def handle(self, *args, **options):
        name = options.get('name')
        if name is None:
            raise CommandError('--name オプションは必須です。')
        gitlab = Gitlab.objects.get(name=name)
        if gitlab is None:
            raise CommandError('%s のGitlab設定が見つかりません。' % name)
        #url = '%s/api/v4/projects/%s/issues?labels=%s' % (gitlab.url, gitlab.project_id, gitlab.labels)
        url = '%s/api/v4/projects/%s/issues?labels=%s' % (gitlab.url, gitlab.project_id, 'Any')
        headers = { 
            'Content-Type': 'application/json',
            'PRIVATE-TOKEN': gitlab.owner_access_token
        }
        res = requests.get(url, headers=headers)
        issues_json = res.json()
        for issue in issues_json:
            del_url = '%s/api/v4/projects/%s/issues/%s' % (gitlab.url, gitlab.project_id, issue['iid'])
            res = requests.delete(del_url, headers=headers)
            print('%s -> %s' % (issue['iid'], res.status_code))

