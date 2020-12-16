from django.contrib import admin
from django import forms
from django.contrib import messages
from django.utils.translation import gettext_lazy as _
from nested_admin import NestedModelAdmin, NestedStackedInline, NestedTabularInline
from .models import Backlog, Gitlab, GitlabVul, GitlabNote, GitlabLib, GoogleChat

import json
import requests

class BacklogAdminForm(forms.ModelForm):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['api_key'].widget.attrs = {'size':100}

    def clean(self):
        cleaned_data = super().clean()
        headers = { 
            'Content-Type': 'application/json'
        }   
        # /api/v2/projects/:projectIdOrKey 
        url = '%s/api/v2/projects/%s?apiKey=%s' % (cleaned_data['url'], cleaned_data['project_key'], cleaned_data['api_key'])
        res = requests.get(url, headers=headers)
        project_id = None
        if res.status_code == 200:
            project_id = res.json()['id']
        if project_id is None:
            raise forms.ValidationError({'project_key':['このプロジェクトキーは存在しません。']})
        self.instance.project_id = project_id

        # /api/v2/projects/:projectIdOrKey/issueTypes 
        url = '%s/api/v2/projects/%s/issueTypes?apiKey=%s' % (cleaned_data['url'], cleaned_data['project_key'], cleaned_data['api_key'])
        res = requests.get(url, headers=headers)
        issuetype_id = None
        if res.status_code == 200:
            for issuetype in res.json():
                if issuetype['name'] == cleaned_data['issuetype_name']:
                    issuetype_id = issuetype['id']
                    break
        if issuetype_id is None:
            self.add_error('issuetype_name', 'この種別は存在しません。')
        self.instance.issuetype_id = issuetype_id

        # /api/v2/priorities 
        url = '%s/api/v2/priorities?apiKey=%s' % (cleaned_data['url'], cleaned_data['api_key'])
        res = requests.get(url, headers=headers)
        priority_id = None
        if res.status_code == 200:
            for priority in res.json():
                if priority['name'] == cleaned_data['priority_name']:
                    priority_id = priority['id']
                    break
        if priority_id is None:
            self.add_error('priority_name', 'この優先度は存在しません。')
        self.instance.priority_id = priority_id

        return cleaned_data

@admin.register(Backlog)
class BacklogAdmin(admin.ModelAdmin):
    form = BacklogAdminForm
    search_fields = ('name', 'url',)
    actions = ['delete_all_issues',]
    list_display = ('name', 'url', 'project_disp', 'issuetype_disp', 'priority_disp')
    fieldsets = [ 
        (None, {'fields': ['name', 'url', 'api_key', 'project_key', 'issuetype_name', 'priority_name']}),
    ]

    def project_disp(self, obj):
        return '%s (%s)' % (obj.project_key, obj.project_id)
    project_disp.short_description = 'プロジェクト'
    project_disp.admin_order_field = 'project_id'

    def issuetype_disp(self, obj):
        return '%s (%s)' % (obj.issuetype_name, obj.issuetype_id)
    issuetype_disp.short_description = '種別'
    issuetype_disp.admin_order_field = 'issuetype_id'

    def priority_disp(self, obj):
        return '%s (%s)' % (obj.priority_name, obj.priority_id)
    priority_disp.short_description = '優先度'
    priority_disp.admin_order_field = 'priority_id'

    def delete_all_issues(self, request, queryset):
        selected = request.POST.getlist(admin.ACTION_CHECKBOX_NAME)
        backlogs = Backlog.objects.filter(pk__in=selected)
        for backlog in backlogs:
            url = '%s/api/v2/issues' % (backlog.url)
            params = {'apiKey': backlog.api_key, 'projectId[]': backlog.project_id, 'count': 100}
            res = requests.get(url, params=params)
            issues_json = res.json()
            del_params = {'apiKey': backlog.api_key}
            for issue in issues_json:
                del_url = '%s/api/v2/issues/%s' % (backlog.url, issue['id'])
                res = requests.delete(del_url, params=del_params)
        self.message_user(request, _('Removed all Backlog issues.'), level=messages.INFO)
    delete_all_issues.short_description = _('Delete all Backlog issues')

    def get_actions(self, request):
        actions = super().get_actions(request)
        actions.pop('delete_selected')
        return actions

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
    readonly_fields = ('note', 'creator', 'created_at', 'updated_at', 'contrast_note_id', 'gitlab_note_id')
    fieldsets = [ 
        (None, {'fields': ['note', ('creator', 'created_at', 'updated_at'), ('contrast_note_id', 'gitlab_note_id')]}),
    ]

    def has_add_permission(self, request):
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
    readonly_fields = ('contrast_org_id', 'contrast_app_id', 'contrast_vul_id', 'gitlab_issue_id')

    def has_add_permission(self, request):
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
    readonly_fields = ('contrast_org_id', 'contrast_app_id', 'contrast_lib_lg', 'contrast_lib_id', 'gitlab_issue_id')

    def has_add_permission(self, request):
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
        (None, {'fields': ['name', 'url', 'project_key', ('vul_labels', 'lib_labels')]}),
        (_('Report User'), {'fields': [('report_username', 'access_token'),]}),
        (_('Option'), {'fields': ['owner_access_token',]}),
    ]

    def vul_count(self, obj):
        return obj.vuls.count()
    vul_count.short_description = 'Vulnerability Count'

    def lib_count(self, obj):
        return obj.libs.count()
    lib_count.short_description = 'Library Count'

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

#@admin.register(GitlabVul)
#class GitlabVulAdmin(admin.ModelAdmin):
#    list_display = ('id',)

@admin.register(GoogleChat)
class GoogleChatAdmin(admin.ModelAdmin):
    search_fields = ('name', 'webhook',)
    list_display = ('name', 'webhook',)

