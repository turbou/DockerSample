from django.contrib import admin
from django import forms
from django.contrib import messages
from django.utils.translation import gettext_lazy as _
from nested_admin import NestedModelAdmin, NestedStackedInline, NestedTabularInline
from application.models import Gitlab, GitlabVul, GitlabNote, GitlabLib, GoogleChat

import json
import requests
import copy

class GitlabNoteInlineForm(forms.ModelForm):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if 'contrast_vul_id' in self.fields:
            self.fields['contrast_vul_id'].widget.attrs = {'size':23}

class GitlabNoteInline(NestedStackedInline):
    model = GitlabNote
    form = GitlabNoteInlineForm
    extra = 0
    ordering = ('-created_at',)
    readonly_fields = ('note', 'creator', 'created_at', 'updated_at', 'contrast_note_id', 'note_id')
    fieldsets = [ 
        (None, {'fields': ['note', ('creator', 'created_at', 'updated_at'), ('contrast_note_id', 'note_id')]}),
    ]

    def has_add_permission(self, request, obj):
        return False

    def has_delete_permission(self, request, obj=None):
        return False

class GitlabVulInlineForm(forms.ModelForm):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if 'contrast_vul_id' in self.fields:
            self.fields['contrast_vul_id'].widget.attrs = {'size':23}

class GitlabVulInline(NestedTabularInline):
    model = GitlabVul
    form = GitlabVulInlineForm
    extra = 0
    inlines = [
        GitlabNoteInline,
    ]
    readonly_fields = ('contrast_org_id', 'contrast_app_id', 'contrast_vul_id', 'issue_id')

    def has_add_permission(self, request, obj):
        return False

    def has_delete_permission(self, request, obj=None):
        return False

class GitlabLibInlineForm(forms.ModelForm):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if 'contrast_lib_lg' in self.fields:
            self.fields['contrast_lib_lg'].widget.attrs = {'size':16}

class GitlabLibInline(NestedTabularInline):
    model = GitlabLib
    form = GitlabLibInlineForm
    extra = 0
    readonly_fields = ('contrast_org_id', 'contrast_app_id', 'contrast_lib_lg', 'contrast_lib_id', 'issue_id')

    def has_add_permission(self, request, obj):
        return False

    def has_delete_permission(self, request, obj=None):
        return False

@admin.register(Gitlab)
class GitlabAdmin(NestedModelAdmin):
    save_on_top = True
    search_fields = ('name', 'url',)
    actions = ['clear_mappings', 'delete_all_issues']
    list_display = ('name', 'url', 'vul_count', 'lib_count')
    inlines = [
        GitlabVulInline,
        GitlabLibInline,
    ]
    fieldsets = [ 
        (None, {'fields': ['name', 'url', 'project_id', ('vul_labels', 'lib_labels')]}),
        (_('Report User'), {'fields': [('report_username', 'access_token'),]}),
        (_('Option'), {'fields': ['owner_access_token',]}),
    ]

    def vul_count(self, obj):
        return obj.vuls.count()
    vul_count.short_description = _('Vulnerability Count')

    def lib_count(self, obj):
        return obj.libs.count()
    lib_count.short_description = _('Library Count')

    def clear_mappings(self, request, queryset):
        selected = request.POST.getlist(admin.ACTION_CHECKBOX_NAME)
        gitlabs = Gitlab.objects.filter(pk__in=selected)
        for gitlab in gitlabs:
            gitlab.vuls.all().delete()
            gitlab.libs.all().delete()
        self.message_user(request, _('Vulnerability, library information cleared.'), level=messages.INFO)
    clear_mappings.short_description = _('Clear Vulnerability and Library Mapping')

    def delete_all_issues(self, request, queryset):
        selected = request.POST.getlist(admin.ACTION_CHECKBOX_NAME)
        gitlabs = Gitlab.objects.filter(pk__in=selected)
        for gitlab in gitlabs:
            url = '%s/api/v4/projects/%s/issues?labels=%s' % (gitlab.url, gitlab.project_id, 'Any')
            headers = { 
                'Content-Type': 'application/json',
                'PRIVATE-TOKEN': gitlab.owner_access_token
            }   
            res = requests.get(url, headers=headers)
            issues_json = res.json()
            for issue in issues_json:
                del_url = '%s/api/v4/projects/%s/issues/%s' % (gitlab.url, gitlab.project_id, issue['iid'])
                res = requests.delete(del_url, headers=headers)
        self.message_user(request, _('Removed all Gitlab issues.'), level=messages.INFO)
    delete_all_issues.short_description = _('Delete all Gitlab issues')

    def get_actions(self, request):
        actions = super().get_actions(request)
        actions.pop('delete_selected')
        return actions

