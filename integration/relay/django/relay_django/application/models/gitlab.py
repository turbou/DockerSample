from django.db import models
from django.core.validators import RegexValidator
from django.utils.translation import gettext_lazy as _

class Gitlab(models.Model):
    name = models.CharField(_('Name'), max_length=20, unique=True,
        validators=[RegexValidator(regex='^[A-Za-z0-9_]{4,20}$', message='名前は半角英数字、アンスコ4文字〜20文字です。')]
    )   
    url = models.URLField(_('URL'), help_text='http://gitlab.gitlab:8085')
    owner_access_token = models.CharField(_('Project Owner\'s Access Token'), max_length=50, help_text=_('For bulk process'), blank=True, null=True)
    report_username = models.CharField(_('Username'), max_length=50, help_text=_('For report user(Project Maintainer is required)'))
    access_token = models.CharField(_('Access Token'), max_length=50)
    project_id = models.CharField(_('Project ID'), max_length=5, help_text='It\'s a number, not a name.')
    vul_labels = models.CharField(_('Labels(Vul)'), max_length=50, help_text='Comma-separated list of label names')
    lib_labels = models.CharField(_('Labels(Lib)'), max_length=50, help_text='Comma-separated list of label names')

    def __str__(self):
        return '%s' % (self.name)

    class Meta:
        verbose_name = _('Gitlab')
        verbose_name_plural = _('Gitlab List')

class GitlabVul(models.Model):
    gitlab = models.ForeignKey(Gitlab, verbose_name=_('Gitlab'), related_name='vuls', related_query_name='vul', on_delete=models.PROTECT)
    contrast_org_id = models.CharField(_('Organization ID'), max_length=36)
    contrast_app_id = models.CharField(_('Application ID'), max_length=36)
    contrast_vul_id = models.CharField(_('Vulnerability ID'), max_length=19, blank=True, null=True)
    gitlab_issue_id = models.PositiveSmallIntegerField(_('Issue IID'))

    def __str__(self):
        if self.id:
            return '%010d' % (self.id)
        return ''

    class Meta:
        verbose_name = _('Gitlab Vulnerability')
        verbose_name_plural = _('Gitlab Vulnerabilities')

class GitlabNote(models.Model):
    vul = models.ForeignKey(GitlabVul, verbose_name=_('Gitlab Vulnerability'), related_name='notes', related_query_name='note', on_delete=models.CASCADE)
    note = models.TextField(_('Note'))
    creator = models.CharField(_('Creator'), max_length=200)
    created_at = models.DateTimeField(_('Created'), blank=True, null=True)
    updated_at = models.DateTimeField(_('Updated'), blank=True, null=True)
    contrast_note_id = models.CharField(_('Contrast Note ID'), max_length=36, unique=True)
    gitlab_note_id = models.PositiveSmallIntegerField(_('Gitlab Comment ID'))

    def __str__(self):
        if self.id:
            return '%010d' % (self.id)
        return ''

    class Meta:
        verbose_name = _('Gitlab Vulnerability Note')
        verbose_name_plural = _('Gitlab Vulnerability Notes')

class GitlabLib(models.Model):
    gitlab = models.ForeignKey(Gitlab, verbose_name=_('Gitlab'), related_name='libs', related_query_name='lib', on_delete=models.PROTECT)
    contrast_org_id = models.CharField(_('Organization ID'), max_length=36)
    contrast_app_id = models.CharField(_('Application ID'), max_length=36)
    contrast_lib_lg = models.CharField(_('Library Language'), max_length=20, blank=True, null=True)
    contrast_lib_id = models.CharField(_('Library ID'), max_length=40, blank=True, null=True)
    gitlab_issue_id = models.PositiveSmallIntegerField(_('Issue IID'))

    def __str__(self):
        if self.id:
            return '%010d' % (self.id)
        return ''

    class Meta:
        verbose_name = _('Gitlab Library')
        verbose_name_plural = _('Gitlab Libraries')

