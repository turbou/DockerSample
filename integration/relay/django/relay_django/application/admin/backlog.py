from django.contrib import admin
from django import forms
from django.contrib import messages
from django.utils.translation import gettext_lazy as _
from nested_admin import NestedModelAdmin, NestedStackedInline, NestedTabularInline
from application.models import Backlog, BacklogVul, BacklogNote, BacklogLib

import json
import requests
import copy

class BacklogNoteInlineForm(forms.ModelForm):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if 'contrast_vul_id' in self.fields:
            self.fields['contrast_vul_id'].widget.attrs = {'size':23}

class BacklogNoteInline(NestedStackedInline):
    model = BacklogNote
    form = BacklogNoteInlineForm
    extra = 0
    ordering = ('-created_at',)
    readonly_fields = ('comment', 'creator', 'created_at', 'updated_at', 'contrast_note_id', 'note_id')
    fieldsets = [ 
        (None, {'fields': ['comment', ('creator', 'created_at', 'updated_at'), ('contrast_note_id', 'note_id')]}),
    ]

    def has_add_permission(self, request):
        return False

    def has_delete_permission(self, request, obj=None):
        return False

class BacklogVulInlineForm(forms.ModelForm):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if 'contrast_vul_id' in self.fields:
            self.fields['contrast_vul_id'].widget.attrs = {'size':23}

class BacklogVulInline(NestedTabularInline):
    model = BacklogVul
    form = BacklogVulInlineForm
    extra = 0
    inlines = [
        BacklogNoteInline,
    ]
    readonly_fields = ('contrast_org_id', 'contrast_app_id', 'contrast_vul_id', 'issue_id')

    def has_add_permission(self, request):
        return False

    def has_delete_permission(self, request, obj=None):
        return False

class BacklogLibInlineForm(forms.ModelForm):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if 'contrast_lib_lg' in self.fields:
            self.fields['contrast_lib_lg'].widget.attrs = {'size':16}

class BacklogLibInline(NestedTabularInline):
    model = BacklogLib
    form = BacklogLibInlineForm
    extra = 0
    readonly_fields = ('contrast_org_id', 'contrast_app_id', 'contrast_lib_lg', 'contrast_lib_id', 'issue_id')

    def has_add_permission(self, request):
        return False

    def has_delete_permission(self, request, obj=None):
        return False

class BacklogAdminForm(forms.ModelForm):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['api_key'].widget.attrs = {'size':100}

    def clean(self):
        cleaned_data = super().clean()
        headers = { 
            'Content-Type': 'application/json'
        }   
        if 'url' in cleaned_data and 'project_key' in cleaned_data and 'api_key' in cleaned_data:
            # /api/v2/projects/:projectIdOrKey 
            url = '%s/api/v2/projects/%s?apiKey=%s' % (cleaned_data['url'], cleaned_data['project_key'], cleaned_data['api_key'])
            res = requests.get(url, headers=headers)
            project_id = None
            if res.status_code == 200:
                project_id = res.json()['id']
            if project_id is None:
                raise forms.ValidationError({'project_key':[_('This ProjectKey does not exist.')]})
            self.instance.project_id = project_id

        if 'url' in cleaned_data and 'project_key' in cleaned_data and 'api_key' in cleaned_data and 'issuetype_name' in cleaned_data:
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
                self.add_error('issuetype_name', _('This IssueType does not exist.'))
            self.instance.issuetype_id = issuetype_id

        if 'url' in cleaned_data and 'api_key' in cleaned_data and 'priority_name' in cleaned_data:
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
                self.add_error('priority_name', _('This Priority does not exist.'))
            self.instance.priority_id = priority_id

        if 'url' in cleaned_data and 'project_key' in cleaned_data and 'api_key' in cleaned_data:
            # /api/v2/projects/:projectIdOrKey/statuses
            url = '%s/api/v2/projects/%s/statuses?apiKey=%s' % (cleaned_data['url'], cleaned_data['project_key'], cleaned_data['api_key'])
            res = requests.get(url, headers=headers)
            print(res.json())
            statuse_tuple = [
                ('status_reported', 'status_reported_id'),
                ('status_suspicious', 'status_suspicious_id'),
                ('status_confirmed', 'status_confirmed_id'),
                ('status_notaproblem', 'status_notaproblem_id'),
                ('status_remediated', 'status_remediated_id'),
                ('status_fixed', 'status_fixed_id'),
            ]
            chk_statuses = [
                'status_reported',
                'status_suspicious',
                'status_confirmed',
                'status_notaproblem',
                'status_remediated',
                'status_fixed',
            ]
            ng_statuses = copy.copy(chk_statuses)
            if res.status_code == 200:
                for chk_status in chk_statuses:
                    if chk_status in cleaned_data and cleaned_data[chk_status]:
                        for status in res.json():
                            if status['name'] == cleaned_data[chk_status]:
                                setattr(self.instance, '%s_id' % chk_status, status['id'])
                                ng_statuses.remove(chk_status)
                    else:
                        ng_statuses.remove(chk_status)
                        continue
            for ng_status in ng_statuses:
                self.add_error(ng_status, _('This Status does not exist.'))

        return cleaned_data

@admin.register(Backlog)
class BacklogAdmin(NestedModelAdmin):
    save_on_top = True
    form = BacklogAdminForm
    search_fields = ('name', 'url',)
    actions = ['clear_mappings', 'delete_all_issues',]
    list_display = ('name', 'url', 'project_disp', 'issuetype_disp', 'priority_disp')
    inlines = [
        BacklogVulInline,
        BacklogLibInline,
    ]
    fieldsets = [ 
        (None, {'fields': ['name', 'url', 'api_key', 'project_key', 'issuetype_name', 'priority_name']}),
        (_('Status Mapping'), {'fields': [
            ('status_reported', 'status_reported_priority'),
            ('status_suspicious', 'status_suspicious_priority'),
            ('status_confirmed', 'status_confirmed_priority'),
            ('status_notaproblem', 'status_notaproblem_priority'),
            ('status_remediated', 'status_remediated_priority'),
            ('status_fixed', 'status_fixed_priority'),
        ]}),
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

    def clear_mappings(self, request, queryset):
        selected = request.POST.getlist(admin.ACTION_CHECKBOX_NAME)
        backlogs = Backlog.objects.filter(pk__in=selected)
        for backlog in backlogs:
            backlog.vuls.all().delete()
            backlog.libs.all().delete()
        self.message_user(request, _('Vulnerability, library information cleared.'), level=messages.INFO)
    clear_mappings.short_description = _('Clear Vulnerability and Library Mapping')

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

