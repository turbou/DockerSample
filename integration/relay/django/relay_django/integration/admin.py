from django.contrib import admin
from django import forms
from .models import Integration

class TeamServerAdminForm(forms.ModelForm):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['authorization'].widget.attrs = {'size':120}
        self.fields['api_key'].widget.attrs = {'size':30}

@admin.register(Integration)
class IntegrationAdmin(admin.ModelAdmin):
    save_on_top = True
    autocomplete_fields = ['backlog', 'gitlab', 'googlechat']
    form = TeamServerAdminForm
    list_display = ('name', 'url',)

    fieldsets = [
        (None, {'fields': ['name', 'url', 'authorization', 'api_key',]}),
        ('Backlog', {'fields': ['backlog',]}),
        ('Gitlab', {'fields': ['gitlab',]}),
        ('GoogleChat', {'fields': ['googlechat',]}),
    ]

