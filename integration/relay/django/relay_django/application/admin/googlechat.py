from django.contrib import admin
from django import forms
from django.contrib import messages
from django.utils.translation import gettext_lazy as _
from nested_admin import NestedModelAdmin, NestedStackedInline, NestedTabularInline
from application.models import GoogleChat

import json
import requests
import copy

@admin.register(GoogleChat)
class GoogleChatAdmin(admin.ModelAdmin):
    search_fields = ('name', 'webhook',)
    list_display = ('name', 'webhook',)

