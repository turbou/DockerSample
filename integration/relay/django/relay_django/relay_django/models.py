from django.db import models
from django.core.validators import RegexValidator

class TeamServerConfig(models.Model):
    config_id = models.CharField('設定ID', max_length=10, unique=True,
        validators=[RegexValidator(regex='^[A-Za-z0-9]{8}$', message='設定IDは半角英数字10文字です。')],
        help_text='このIDをTeamServerのPayloadに設定してください。'
    )
    url = models.URLField('TeamServer URL', help_text='http://172.31.47.104:8080/Contrast')
    authorization = models.CharField('AUTHORIZATION', max_length=100, unique=True)
    api_key = models.CharField('API_KEY', max_length=50, unique=True)

    def __str__(self):
        return '%s' % (self.config_id)

    class Meta:
        verbose_name = 'TeamServer設定'
        verbose_name_plural = 'TeamServer設定一覧'

class Backlog(models.Model):
    #teamserver = models.ForeignKey(TeamServerConfig, verbose_name='TeamServer設定', related_name='backlogs', related_query_name='backlog', on_delete=models.CASCADE)
    teamserver = models.OneToOneField(TeamServerConfig, verbose_name='TeamServer設定', on_delete=models.CASCADE)
    url = models.URLField('Backlog URL', help_text='https://tabocom.backlog.com')

    def __str__(self):
        return '%s' % (self.url)

    class Meta:
        verbose_name = 'Backlog連携'
        verbose_name_plural = 'Backlog連携一覧'

class Gitlab(models.Model):
    #teamserver = models.ForeignKey(TeamServerConfig, verbose_name='TeamServer設定', related_name='gitlabs', related_query_name='gitlab', on_delete=models.CASCADE)
    teamserver = models.OneToOneField(TeamServerConfig, verbose_name='TeamServer設定', on_delete=models.CASCADE)
    url = models.URLField('Gitlab URL', help_text='http://gitlab.gitlab:8085')

    def __str__(self):
        return '%s' % (self.url)

    class Meta:
        verbose_name = 'Gitlab連携'
        verbose_name_plural = 'Gitlab連携一覧'

