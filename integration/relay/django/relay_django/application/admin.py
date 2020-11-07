from django.contrib import admin
from django import forms
from .models import Backlog, Gitlab, GitlabMapping, GoogleChat

class BacklogAdminForm(forms.ModelForm):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['api_key'].widget.attrs = {'size':100}

@admin.register(Backlog)
class BacklogAdmin(admin.ModelAdmin):
    form = BacklogAdminForm
    search_fields = ('name', 'url',)
    list_display = ('name', 'url',)

class GitlabMappingInlineForm(forms.ModelForm):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if 'contrast_vul_id' in self.fields:
            self.fields['contrast_vul_id'].widget.attrs = {'size':23}
        if 'contrast_lib_lg' in self.fields:
            self.fields['contrast_lib_lg'].widget.attrs = {'size':16}

class GitlabMappingInline(admin.TabularInline):
    model = GitlabMapping
    form = GitlabMappingInlineForm
    extra = 0
    readonly_fields = ('contrast_org_id', 'contrast_app_id', 'contrast_vul_id', 'contrast_lib_lg', 'contrast_lib_id', 'gitlab_issue_id')

@admin.register(Gitlab)
class GitlabAdmin(admin.ModelAdmin):
    search_fields = ('name', 'url',)
    list_display = ('name', 'url',)
    inlines = [
        GitlabMappingInline,
    ]

#@admin.register(GitlabMapping)
#class GitlabMappingAdmin(admin.ModelAdmin):
#    list_display = ('id',)

@admin.register(GoogleChat)
class GoogleChatAdmin(admin.ModelAdmin):
    search_fields = ('name', 'webhook',)
    list_display = ('name', 'webhook',)

