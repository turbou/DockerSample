from django.db import models
from django.core.validators import RegexValidator

class Backlog(models.Model):
    name = models.CharField('名前', max_length=10, unique=True,
        validators=[RegexValidator(regex='^[A-Za-z0-9]{4,10}$', message='名前は半角英数字4文字〜10文字です。')]
    )
    url = models.URLField('URL', help_text='https://tabocom.backlog.com')
    api_key = models.CharField('API_KEY', max_length=100)
    project_id = models.CharField('プロジェクトID', max_length=10)
    issuetype_id = models.CharField('種別ID', max_length=10)
    priority_id = models.CharField('優先度ID', max_length=1)

    def __str__(self):
        return '%s(%s)' % (self.name, self.url)

    class Meta:
        verbose_name = 'Backlog設定'
        verbose_name_plural = 'Backlog設定一覧'

class Gitlab(models.Model):
    name = models.CharField('名前', max_length=10, unique=True,
        validators=[RegexValidator(regex='^[A-Za-z0-9]{4,10}$', message='名前は半角英数字4文字〜10文字です。')]
    )
    url = models.URLField('URL', help_text='http://gitlab.gitlab:8085')
    access_token = models.CharField('アクセストークン', max_length=50)
    project_id = models.CharField('プロジェクトID', max_length=5)
    labels = models.CharField('ラベル', max_length=50)

    def __str__(self):
        return '%s(%s)' % (self.name, self.url)

    class Meta:
        verbose_name = 'Gitlab設定'
        verbose_name_plural = 'Gitlab設定一覧'

class TeamServer(models.Model):
    name = models.CharField('名前', max_length=10, unique=True,
        validators=[RegexValidator(regex='^[A-Za-z0-9]{4,10}$', message='名前は半角英数字4文字〜10文字です。')],
        help_text='この名前をTeamServerのPayloadに設定してください。'
    )
    url = models.URLField('TeamServer URL', help_text='http://172.31.47.104:8080/Contrast')
    authorization = models.CharField('AUTHORIZATION', max_length=100, unique=True)
    api_key = models.CharField('API_KEY', max_length=50, unique=True)
    backlog = models.ForeignKey(Backlog, verbose_name='Backlog', related_name='teamservers', related_query_name='teamserver', on_delete=models.SET_NULL, blank=True, null=True)
    gitlab = models.ForeignKey(Gitlab, verbose_name='Gitlab', related_name='teamservers', related_query_name='teamserver', on_delete=models.SET_NULL, blank=True, null=True)

    def __str__(self):
        return '%s' % (self.name)

    class Meta:
        verbose_name = 'TeamServer設定'
        verbose_name_plural = 'TeamServer設定一覧'

