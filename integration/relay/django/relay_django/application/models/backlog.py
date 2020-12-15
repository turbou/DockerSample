from django.db import models
from django.core.validators import RegexValidator
from django.utils.translation import gettext_lazy as _

class Backlog(models.Model):
    name = models.CharField('Name', max_length=20, unique=True,
        validators=[RegexValidator(regex='^[A-Za-z0-9_]{4,20}$', message='名前は半角英数字、アンスコ4文字〜20文字です。')]
    )
    url = models.URLField('URL', help_text='https://tabocom.backlog.com')
    api_key = models.CharField('API_KEY', max_length=100)
    project_id = models.CharField('Project ID', max_length=10)
    issuetype_id = models.CharField('Category ID', max_length=10)
    priority_id = models.CharField('Priority ID', max_length=1)

    def __str__(self):
        return '%s' % (self.name)

    class Meta:
        verbose_name = _('Backlog')
        verbose_name_plural = _('Backlog List')

