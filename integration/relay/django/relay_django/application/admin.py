from django.contrib import admin
from django import forms
from django.contrib import messages
from nested_admin import NestedModelAdmin, NestedStackedInline, NestedTabularInline
from .models import Backlog, Gitlab, GitlabVul, GitlabNote, GitlabLib, GoogleChat

class BacklogAdminForm(forms.ModelForm):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['api_key'].widget.attrs = {'size':100}

@admin.register(Backlog)
class BacklogAdmin(admin.ModelAdmin):
    form = BacklogAdminForm
    search_fields = ('name', 'url',)
    list_display = ('name', 'url',)

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
    actions = ['clear_mappings',]
    list_display = ('name', 'url', 'vul_count', 'lib_count')
    inlines = [
        GitlabVulInline,
        GitlabLibInline,
    ]
    fieldsets = [ 
        (None, {'fields': ['name', 'url', 'project_id', ('vul_labels', 'lib_labels')]}),
        ('Report User', {'fields': [('report_username', 'access_token'),]}),
        ('Option', {'fields': ['owner_access_token',]}),
    ]

    def vul_count(self, obj):
        return obj.vuls.count()
    vul_count.short_description = '脆弱性数'

    def lib_count(self, obj):
        return obj.libs.count()
    lib_count.short_description = 'ライブラリ数'

    def clear_mappings(self, request, queryset):
        selected = request.POST.getlist(admin.ACTION_CHECKBOX_NAME)
        gitlabs = Gitlab.objects.filter(pk__in=selected)
        for gitlab in gitlabs:
            gitlab.vuls.all().delete()
            gitlab.libs.all().delete()
        self.message_user(request, '脆弱性、ライブラリの情報をクリアしました。', level=messages.INFO)
    clear_mappings.short_description = '脆弱性、ライブラリ情報のクリア'

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

