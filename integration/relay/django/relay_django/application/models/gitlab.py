from django.db import models
from django.core.validators import RegexValidator

class Gitlab(models.Model):
    name = models.CharField('名前', max_length=20, unique=True,
        validators=[RegexValidator(regex='^[A-Za-z0-9_]{4,20}$', message='名前は半角英数字、アンスコ4文字〜20文字です。')]
    )   
    url = models.URLField('URL', help_text='http://gitlab.gitlab:8085')
    owner_access_token = models.CharField('Owner\'s Access Token', max_length=50, help_text='For bulk process', blank=True, null=True)
    report_username = models.CharField('Username', max_length=50, help_text='For report user(Project Maintainer is required)')
    access_token = models.CharField('Access Token', max_length=50, help_text='For report user')
    project_id = models.CharField('Project ID', max_length=5, help_text='It\'s a number, not a name.')
    vul_labels = models.CharField('Labels(Vul)', max_length=50, help_text='Comma-separated list of label names')
    lib_labels = models.CharField('Labels(Lib)', max_length=50, help_text='Comma-separated list of label names')

    def __str__(self):
        return '%s' % (self.name)

    class Meta:
        verbose_name = 'Gitlab設定'
        verbose_name_plural = 'Gitlab設定一覧'

class GitlabVul(models.Model):
    gitlab = models.ForeignKey(Gitlab, verbose_name='Gitlab', related_name='vuls', related_query_name='vul', on_delete=models.PROTECT)
    contrast_org_id = models.CharField('組織ID', max_length=36)
    contrast_app_id = models.CharField('アプリID', max_length=36)
    contrast_vul_id = models.CharField('脆弱性ID', max_length=19, blank=True, null=True)
    gitlab_issue_id = models.PositiveSmallIntegerField('Issue ID')

    def __str__(self):
        if self.id:
            return '%010d' % (self.id)
        return ''

    class Meta:
        verbose_name = 'Gitlab脆弱性'
        verbose_name_plural = 'Gitlab脆弱性一覧'

class GitlabNote(models.Model):
    vul = models.ForeignKey(GitlabVul, verbose_name='Gitlab脆弱性', related_name='notes', related_query_name='note', on_delete=models.CASCADE)
    note = models.TextField('コメント')
    creator = models.CharField('投稿者', max_length=200)
    created_at = models.DateTimeField('投稿日時', blank=True, null=True)
    updated_at = models.DateTimeField('更新日時', blank=True, null=True)
    contrast_note_id = models.CharField('ContrastNoteID', max_length=36, unique=True)
    gitlab_note_id = models.PositiveSmallIntegerField('GitlabNoteID')

    def __str__(self):
        if self.id:
            return '%010d' % (self.id)
        return ''

    class Meta:
        verbose_name = 'Gitlab脆弱性コメント'
        verbose_name_plural = 'Gitlab脆弱性コメント一覧'

class GitlabLib(models.Model):
    gitlab = models.ForeignKey(Gitlab, verbose_name='Gitlab', related_name='libs', related_query_name='lib', on_delete=models.PROTECT)
    contrast_org_id = models.CharField('組織ID', max_length=36)
    contrast_app_id = models.CharField('アプリID', max_length=36)
    contrast_lib_lg = models.CharField('ライブラリ言語', max_length=20, blank=True, null=True)
    contrast_lib_id = models.CharField('ライブラリID', max_length=40, blank=True, null=True)
    gitlab_issue_id = models.PositiveSmallIntegerField('Issue ID')

    def __str__(self):
        if self.id:
            return '%010d' % (self.id)
        return ''

    class Meta:
        verbose_name = 'Gitlabライブラリ'
        verbose_name_plural = 'Gitlabライブラリ一覧'

