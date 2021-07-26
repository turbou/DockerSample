from django.db import models
from django.core.validators import RegexValidator
from django.utils.translation import gettext_lazy as _

class Redmine(models.Model):
    name = models.CharField(_('Name'), max_length=20, unique=True,
        validators=[RegexValidator(regex='^[A-Za-z0-9_]{4,20}$', message='名前は半角英数字、アンスコ4文字〜20文字です。')]
    )   
    url = models.URLField(_('URL'), help_text='http://redmine.redmine:8085')
    access_key = models.CharField(_('Access Key'), max_length=50)
    project_id = models.CharField(_('Project ID'), max_length=50, help_text='Project ID, not a Project name.')
    tracker_name = models.CharField(_('Tracker Name'), max_length=50, help_text='Tracker Name, not a Tracker ID.')
    tracker_id = models.PositiveIntegerField(_('Tracker ID'), blank=True, null=True)

    def __str__(self):
        return '%s' % (self.name)

    class Meta:
        verbose_name = _('Redmine')
        verbose_name_plural = _('Redmine List')

class RedmineVul(models.Model):
    redmine = models.ForeignKey(Redmine, verbose_name=_('Redmine'), related_name='vuls', related_query_name='vul', on_delete=models.PROTECT)
    contrast_org_id = models.CharField(_('Organization ID'), max_length=36)
    contrast_app_id = models.CharField(_('Application ID'), max_length=36)
    contrast_vul_id = models.CharField(_('Vulnerability ID'), max_length=19)
    issue_id = models.CharField(_('Issue ID'), max_length=100)

    def __str__(self):
        if self.id:
            return '%010d' % (self.id)
        return ''

    class Meta:
        verbose_name = _('Redmine Vulnerability')
        verbose_name_plural = _('Redmine Vulnerabilities')

class RedmineNote(models.Model):
    vul = models.ForeignKey(RedmineVul, verbose_name=_('Redmine Vulnerability'), related_name='notes', related_query_name='note', on_delete=models.CASCADE)
    note = models.TextField(_('Note'))
    creator = models.CharField(_('Creator'), max_length=200)
    created_at = models.DateTimeField(_('Created'), blank=True, null=True)
    updated_at = models.DateTimeField(_('Updated'), blank=True, null=True)
    contrast_note_id = models.CharField(_('Contrast Note ID'), max_length=36, unique=True)
    note_id = models.CharField(_('Redmine Comment ID'), max_length=100)

    def __str__(self):
        if self.id:
            return '%010d' % (self.id)
        return ''

    class Meta:
        verbose_name = _('Redmine Vulnerability Note')
        verbose_name_plural = _('Redmine Vulnerability Notes')

class RedmineLib(models.Model):
    redmine = models.ForeignKey(Redmine, verbose_name=_('Redmine'), related_name='libs', related_query_name='lib', on_delete=models.PROTECT)
    contrast_org_id = models.CharField(_('Organization ID'), max_length=36)
    contrast_app_id = models.CharField(_('Application ID'), max_length=36)
    contrast_lib_lg = models.CharField(_('Library Language'), max_length=20, blank=True, null=True)
    contrast_lib_id = models.CharField(_('Library ID'), max_length=40, blank=True, null=True)
    issue_id = models.CharField(_('Issue ID'), max_length=100)

    def __str__(self):
        if self.id:
            return '%010d' % (self.id)
        return ''

    class Meta:
        verbose_name = _('Redmine Library')
        verbose_name_plural = _('Redmine Libraries')

