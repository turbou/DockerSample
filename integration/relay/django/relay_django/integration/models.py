from django.db import models
from django.core.validators import RegexValidator
from application.models import Backlog, Gitlab, GoogleChat

class Integration(models.Model):
    name = models.CharField('名前', max_length=20, unique=True,
        validators=[RegexValidator(regex='^[A-Za-z0-9_]{4,20}$', message='名前は半角英数字、アンスコ4文字〜10文字です。')],
        help_text='この名前をTeamServerのPayloadに設定してください。'
    )
    url = models.URLField('TeamServer URL', help_text='http://172.31.47.104:8080/Contrast')
    authorization = models.CharField('AUTHORIZATION', max_length=100, unique=True)
    api_key = models.CharField('API_KEY', max_length=50, unique=True)
    backlog = models.ForeignKey(Backlog, verbose_name='Backlog', related_name='integrations', related_query_name='integration', on_delete=models.SET_NULL, blank=True, null=True)
    gitlab = models.ForeignKey(Gitlab, verbose_name='Gitlab', related_name='integrations', related_query_name='integration', on_delete=models.SET_NULL, blank=True, null=True)
    googlechat = models.ForeignKey(GoogleChat, verbose_name='GoogleChat', related_name='integrations', related_query_name='integration', on_delete=models.SET_NULL, blank=True, null=True)

    def __str__(self):
        return '%s' % (self.name)

    class Meta:
        verbose_name = 'Integration設定'
        verbose_name_plural = 'Integration設定一覧'

