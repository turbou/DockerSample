from django.contrib import admin
from django import forms
from django.contrib import messages
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
    save_on_top = True
    search_fields = ('name', 'url',)
    actions = ['clear_mappings',]
    list_display = ('name', 'url', 'mapping_count')
    inlines = [
        GitlabMappingInline,
    ]
    fieldsets = [ 
        (None, {'fields': ['name', 'url', 'project_id', ('vul_labels', 'lib_labels')]}),
        ('Report User', {'fields': [('report_username', 'access_token'),]}),
        ('Option', {'fields': ['owner_access_token',]}),
    ]

    def mapping_count(self, obj):
        return obj.mappings.count()
    mapping_count.short_description = 'マッピング数'

    def clear_mappings(self, request, queryset):
        selected = request.POST.getlist(admin.ACTION_CHECKBOX_NAME)
        gitlabs = Gitlab.objects.filter(pk__in=selected)
        for gitlab in gitlabs:
            gitlab.mappings.all().delete()
        self.message_user(request, 'マッピングをクリアしました。', level=messages.INFO)
    clear_mappings.short_description = 'マッピングのクリア'

    def get_actions(self, request):
        actions = super().get_actions(request)
        actions.pop('delete_selected')
        return actions

#@admin.register(GitlabMapping)
#class GitlabMappingAdmin(admin.ModelAdmin):
#    list_display = ('id',)

@admin.register(GoogleChat)
class GoogleChatAdmin(admin.ModelAdmin):
    search_fields = ('name', 'webhook',)
    list_display = ('name', 'webhook',)

