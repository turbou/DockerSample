from django.core.management.base import BaseCommand, CommandError
from django.conf import settings

import json
import requests

class Command(BaseCommand):
    help = 'Backlogのissueを一括削除します。'

    def add_arguments(self, parser):
        parser.add_argument(
            '--apikey', dest='apikey', default=None,
            help='BacklogのAPI-Keyを指定してください。',
        )
        parser.add_argument(
            '--projectid', dest='projectid', default=None,
            help='BacklogのprojectIdを指定してください。',
        )

    def handle(self, *args, **options):
        apikey = options.get('apikey')
        projectid = options.get('projectid')
        if apikey is None or projectid is None:
            raise CommandError('--apikey, --projectid オプションは必須です。')
        url = '%s/api/v2/issues' % (settings.BACKLOG_URL)
        params = {'apiKey': apikey, 'projectId[]': projectid, 'count': 100}
        res = requests.get(url, params=params)
        issues_json = res.json()
        del_params = {'apiKey': apikey}
        for issue in issues_json:
            del_url = '%s/api/v2/issues/%s' % (settings.BACKLOG_URL, issue['id'])
            res = requests.delete(del_url, params=del_params)
            print(res.status_code)

