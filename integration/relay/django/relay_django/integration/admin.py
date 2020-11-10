from django.contrib import admin
from django import forms
from .models import Integration

class TeamServerAdminForm(forms.ModelForm):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['name'].widget.attrs = {'size':30}
        self.fields['api_key'].widget.attrs = {'size':80}
        self.fields['username'].widget.attrs = {'size':80}
        self.fields['service_key'].widget.attrs = {'size':80}

@admin.register(Integration)
class IntegrationAdmin(admin.ModelAdmin):
    save_on_top = True
    autocomplete_fields = ['backlog', 'gitlab', 'googlechat']
    form = TeamServerAdminForm
    actions = None
    list_display = ('name', 'url', 'username')

    fieldsets = [
        (None, {'fields': ['name', 'url', 'api_key', 'username', 'service_key']}),
        ('Backlog', {'fields': ['backlog',]}),
        ('Gitlab', {'fields': ['gitlab',]}),
        ('GoogleChat', {'fields': ['googlechat',]}),
    ]

