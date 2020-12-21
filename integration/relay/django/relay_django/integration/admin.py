from django.contrib import admin
from django.conf import settings
from django import forms
from django.utils.safestring import mark_safe
from django.utils.translation import gettext_lazy as _
from .models import Integration

import json
import requests
import base64

class TeamServerAdminForm(forms.ModelForm):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['name'].widget.attrs = {'size':30}
        self.fields['org_id'].widget.attrs = {'size':80}
        self.fields['api_key'].widget.attrs = {'size':80}
        self.fields['username'].widget.attrs = {'size':80}
        self.fields['service_key'].widget.attrs = {'size':80}

    def clean(self):
        cleaned_data = super().clean()
        if 'url' in cleaned_data and 'org_id' in cleaned_data and 'api_key' in cleaned_data and 'username' in cleaned_data and 'service_key' in cleaned_data:
            url = '%s/api/ng/%s/organizations/' % (cleaned_data['url'], cleaned_data['org_id'])
            authorization = base64.b64encode(('%s:%s' % (cleaned_data['username'], cleaned_data['service_key'])).encode('utf-8'))
            headers = { 
                'Authorization': authorization,
                'API-Key': cleaned_data['api_key'],
                'Content-Type': 'application/json',
                'Accept': 'application/json',
            } 
            res = requests.get(url, headers=headers)
            if res.status_code != requests.codes.ok: # 200
                raise forms.ValidationError(_('Unable to connect to Team Server. Please check the settings.'))
        return cleaned_data

@admin.register(Integration)
class IntegrationAdmin(admin.ModelAdmin):
    save_on_top = True
    save_as = True
    autocomplete_fields = ['backlog', 'gitlab', 'googlechat']
    form = TeamServerAdminForm
    actions = None
    list_display = ('name', 'url', 'username', 'hook_url')

    fieldsets = [
        (None, {'fields': ['name', 'url', 'org_id', 'api_key', 'username', 'service_key']}),
        ('Backlog', {'fields': ['backlog',]}),
        ('Gitlab', {'fields': ['gitlab',]}),
        ('GoogleChat', {'fields': ['googlechat',]}),
    ]

    def hook_url(self, obj):
        script_name = ''
        if settings.USE_X_FORWARDED_HOST:
            script_name = settings.FORCE_SCRIPT_NAME
        msg_buffer = []
        msg_buffer.append('TeamServer Generic Webhook => http://XXXXXXXXXX%s/hook/' % script_name)
        msg_buffer.append('Gitlab Project Webhook => http://XXXXXXXXXX%s/gitlab/' % script_name)
        return mark_safe('<br />'.join(msg_buffer))
    hook_url.short_description = 'HOOK URL'

