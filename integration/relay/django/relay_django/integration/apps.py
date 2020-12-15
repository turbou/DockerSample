from django.apps import AppConfig
from django.utils.translation import gettext_lazy as _


class IntegrationConfig(AppConfig):
    name = 'integration'
    verbose_name = _('integration')
