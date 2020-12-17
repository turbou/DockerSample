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
    # Status
    status_reported = models.CharField(_('Reported'), max_length=50, blank=True, null=True)
    status_reported_id = models.CharField(_('Reported ID'), max_length=10, blank=True, null=True)
    status_suspicious = models.CharField(_('Suspicious'), max_length=50, blank=True, null=True)
    status_suspicious_id = models.CharField(_('Suspicious ID'), max_length=10, blank=True, null=True)
    status_confirmed = models.CharField(_('Confirmed'), max_length=50, blank=True, null=True)
    status_confirmed_id = models.CharField(_('Confirmed ID'), max_length=50, blank=True, null=True)
    status_notaproblem = models.CharField(_('Not a Problem'), max_length=50, blank=True, null=True)
    status_notaproblem_id = models.CharField(_('Not a Problem ID'), max_length=50, blank=True, null=True)
    status_remediated = models.CharField(_('Remediated'), max_length=50, blank=True, null=True)
    status_remediated_id = models.CharField(_('Remediated ID'), max_length=50, blank=True, null=True)
    status_fixed = models.CharField(_('Fixed'), max_length=50, blank=True, null=True)
    status_fixed_id = models.CharField(_('Fixed ID'), max_length=50, blank=True, null=True)

    def __str__(self):
        return '%s' % (self.name)

    class Meta:
        verbose_name = _('Backlog')
        verbose_name_plural = _('Backlog List')

class BacklogVul(models.Model):
    backlog = models.ForeignKey(Backlog, verbose_name=_('Backlog'), related_name='vuls', related_query_name='vul', on_delete=models.PROTECT)
    contrast_org_id = models.CharField(_('Organization ID'), max_length=36)
    contrast_app_id = models.CharField(_('Application ID'), max_length=36)
    contrast_vul_id = models.CharField(_('Vulnerability ID'), max_length=19, blank=True, null=True)
    backlog_issue_id = models.PositiveSmallIntegerField(_('Issue ID'))

    def __str__(self):
        if self.id:
            return '%010d' % (self.id)
        return ''

    class Meta:
        verbose_name = _('Backlog Vulnerability')
        verbose_name_plural = _('Backlog Vulnerabilities')

class BacklogComment(models.Model):
    vul = models.ForeignKey(BacklogVul, verbose_name=_('Backlog Vulnerability'), related_name='comments', related_query_name='comment', on_delete=models.CASCADE)
    comment = models.TextField(_('Comment'))
    creator = models.CharField(_('Creator'), max_length=200)
    created_at = models.DateTimeField(_('Created'), blank=True, null=True)
    updated_at = models.DateTimeField(_('Updated'), blank=True, null=True)
    contrast_note_id = models.CharField(_('Contrast Note ID'), max_length=36, unique=True)
    backlog_comment_id = models.PositiveSmallIntegerField(_('Backlog Comment ID'))

    def __str__(self):
        if self.id:
            return '%010d' % (self.id)
        return ''

    class Meta:
        verbose_name = _('Backlog Vulnerability Comment')
        verbose_name_plural = _('Backlog Vulnerability Comments')

class BacklogLib(models.Model):
    backlog = models.ForeignKey(Backlog, verbose_name=_('Backlog'), related_name='libs', related_query_name='lib', on_delete=models.PROTECT)
    contrast_org_id = models.CharField(_('Organization ID'), max_length=36)
    contrast_app_id = models.CharField(_('Application ID'), max_length=36)
    contrast_lib_lg = models.CharField(_('Library Language'), max_length=20, blank=True, null=True)
    contrast_lib_id = models.CharField(_('Library ID'), max_length=40, blank=True, null=True)
    backlog_issue_id = models.PositiveSmallIntegerField(_('Issue ID'))

    def __str__(self):
        if self.id:
            return '%010d' % (self.id)
        return ''

    class Meta:
        verbose_name = _('Backlog Library')
        verbose_name_plural = _('Backlog Libraries')

