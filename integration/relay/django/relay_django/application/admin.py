from django.contrib import admin
from django import forms
from .models import Backlog, Gitlab, GoogleChat

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

@admin.register(GoogleChat)
class GoogleChatAdmin(admin.ModelAdmin):
    search_fields = ('name', 'webhook',)
    list_display = ('name', 'webhook',)

