from celery import shared_task
from celery.utils.log import get_task_logger
from django.core.management import call_command
from application.models import Redmine
from redminelib import Redmine as RedmineApi

@shared_task
def redmine_sample_task():
    for redmine in Redmine.objects.all():
        redmine_api = RedmineApi(redmine.url, key=redmine.access_key)
        issues = redmine_api.issue.filter(project_id=redmine.project_id, sort='category:desc')
        for issue in issues:
            for journal in issue.journals:
                print(issue.subject, journal.notes)

