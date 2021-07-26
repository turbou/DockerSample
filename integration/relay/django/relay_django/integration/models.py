from django.db import models
from django.core.validators import RegexValidator
from django.utils.translation import gettext_lazy as _
from application.models import Backlog, Gitlab, GoogleChat, Redmine

class Integration(models.Model):
    name = models.CharField(_('Name'), max_length=20, unique=True,
        validators=[RegexValidator(regex='^[A-Za-z0-9_]{1,20}$', message='名前は半角英数字、アンスコ1文字〜20文字です。')],
        help_text=_('Set this name to the TeamServer Generic Webhook Payload.')
    )
    url = models.URLField(_('TeamServer URL'), help_text=_('e.g. https://app.contrastsecurity.com/Contrast'))
    org_id = models.CharField(_('Organization ID'), max_length=36, unique=False)
    api_key = models.CharField(_('API Key'), max_length=50, unique=False)
    username = models.CharField(_('Username'), max_length=20, unique=False, help_text=_('Login ID (mail address)'))
    service_key = models.CharField(_('Service Key'), max_length=20, unique=False)
    backlog = models.ForeignKey(Backlog, verbose_name='Backlog', related_name='integrations', related_query_name='integration', on_delete=models.SET_NULL, blank=True, null=True)
    gitlab = models.ForeignKey(Gitlab, verbose_name='Gitlab', related_name='integrations', related_query_name='integration', on_delete=models.SET_NULL, blank=True, null=True)
    googlechat = models.ForeignKey(GoogleChat, verbose_name='GoogleChat', related_name='integrations', related_query_name='integration', on_delete=models.SET_NULL, blank=True, null=True)
    redmine = models.ForeignKey(Redmine, verbose_name='Redmine', related_name='integrations', related_query_name='integration', on_delete=models.SET_NULL, blank=True, null=True)

    def __str__(self):
        return '%s' % (self.name)

    class Meta:
        verbose_name = _('Integration')
        verbose_name_plural = _('Integration List')

