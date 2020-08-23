from django.contrib import admin
from django import forms
from .models import TeamServerConfig, Backlog, Gitlab

class BacklogAdminInline(admin.StackedInline):
    model = Backlog
    extra = 1
    max_num = 1

class GitlabAdminInline(admin.StackedInline):
    model = Gitlab
    extra = 1
    max_num = 1

class TeamServerConfigAdminForm(forms.ModelForm):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['authorization'].widget.attrs = {'size':120}
        self.fields['api_key'].widget.attrs = {'size':30}

@admin.register(TeamServerConfig)
class TeamServerConfigAdmin(admin.ModelAdmin):
    save_on_top = True
    form = TeamServerConfigAdminForm
    inlines = [BacklogAdminInline, GitlabAdminInline]
    list_display = ('config_id', 'url',)

