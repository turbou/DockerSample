from django.contrib import admin
from django import forms
from .models import TeamServer, Backlog, Gitlab

class BacklogAdminForm(forms.ModelForm):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['api_key'].widget.attrs = {'size':100}

@admin.register(Backlog)
class BacklogAdmin(admin.ModelAdmin):
    form = BacklogAdminForm
    search_fields = ('name', 'url',)
    list_display = ('name', 'url',)

@admin.register(Gitlab)
class GitlabAdmin(admin.ModelAdmin):
    search_fields = ('name', 'url',)
    list_display = ('name', 'url',)

class TeamServerAdminForm(forms.ModelForm):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['authorization'].widget.attrs = {'size':120}
        self.fields['api_key'].widget.attrs = {'size':30}

@admin.register(TeamServer)
class TeamServerAdmin(admin.ModelAdmin):
    save_on_top = True
    autocomplete_fields = ['backlog', 'gitlab']
    form = TeamServerAdminForm
    list_display = ('name', 'url',)

