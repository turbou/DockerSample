from django.db import models
from django.core.validators import RegexValidator

class Gitlab(models.Model):
    name = models.CharField('名前', max_length=20, unique=True,
        validators=[RegexValidator(regex='^[A-Za-z0-9_]{4,20}$', message='名前は半角英数字、アンスコ4文字〜20文字です。')]
    )   
    url = models.URLField('URL', help_text='http://gitlab.gitlab:8085')
    access_token = models.CharField('アクセストークン', max_length=50)
    project_id = models.CharField('プロジェクトID', max_length=5)
    labels = models.CharField('ラベル', max_length=50)

    def __str__(self):
        return '%s' % (self.name)

    class Meta:
        verbose_name = 'Gitlab設定'
        verbose_name_plural = 'Gitlab設定一覧'

