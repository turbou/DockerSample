from django.db import models
from django.core.validators import RegexValidator

class Backlog(models.Model):
    name = models.CharField('名前', max_length=20, unique=True,
        validators=[RegexValidator(regex='^[A-Za-z0-9_]{4,20}$', message='名前は半角英数字、アンスコ4文字〜20文字です。')]
    )
    url = models.URLField('URL', help_text='https://tabocom.backlog.com')
    api_key = models.CharField('API_KEY', max_length=100)
    project_id = models.CharField('プロジェクトID', max_length=10)
    issuetype_id = models.CharField('種別ID', max_length=10)
    priority_id = models.CharField('優先度ID', max_length=1)

    def __str__(self):
        return '%s' % (self.name)

    class Meta:
        verbose_name = 'Backlog設定'
        verbose_name_plural = 'Backlog設定一覧'

