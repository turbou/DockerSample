from django.db import models
from django.core.validators import RegexValidator
from django.utils.translation import gettext_lazy as _

class Backlog(models.Model):
    name = models.CharField(_('Name'), max_length=20, unique=True,
        validators=[RegexValidator(regex='^[A-Za-z0-9_]{4,20}$', message='名前は半角英数字、アンスコ4文字〜20文字です。')]
    )
    url = models.URLField(_('URL'), help_text='https://tabocom.backlog.com')
    api_key = models.CharField(_('API Key'), max_length=100)
    project_key = models.CharField(_('Project Key'), max_length=100)
    project_id = models.CharField(_('Project ID'), max_length=10, blank=True, null=True)
    issuetype_name = models.CharField(_('IssueType Name'), max_length=100)
    issuetype_id = models.CharField(_('IssueType ID'), max_length=10, blank=True, null=True)
    priority_name = models.CharField(_('Priority Name'), max_length=100)
    priority_id = models.CharField(_('Priority ID'), max_length=10, blank=True, null=True)
    #status_reported = models.CharField(_('Reported'), max_length=1)
    #status_suspicious = models.CharField(_('Priority'), max_length=1)
    #status_confirmed = models.CharField(_('Priority'), max_length=1)
    #status_notaproblem = models.CharField(_('Priority'), max_length=1)
    #status_remediated = models.CharField(_('Priority'), max_length=1)
    #status_fixed = models.CharField(_('Priority'), max_length=1)

    def __str__(self):
        return '%s' % (self.name)

    class Meta:
        verbose_name = _('Backlog')
        verbose_name_plural = _('Backlog List')

