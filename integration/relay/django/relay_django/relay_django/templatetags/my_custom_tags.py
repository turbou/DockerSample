from django import template
from django.template.base import Node, NodeList, Template, Context, Variable
from django.conf import settings
from re import sub
from datetime import datetime
from django.utils import dateformat
from django.template.defaultfilters import stringfilter
from decimal import Decimal
from django.utils.safestring import mark_safe
from django.urls import reverse

register = template.Library()

class AppOrderNode(Node):
    """
        Reorders the app_list and child model lists on the admin index page.
    """
    def render(self, context):
        if 'app_list' in context:
            admin_order = settings.MY_ADMIN_REORDER
            app_list = list(context['app_list'])
            ordered = []
            for my_app in admin_order:
                my_app_name, my_app_models = my_app[0], my_app[1]
                for app_def in app_list:
                    if app_def['app_label'] == my_app_name:
                        model_list = list(app_def['models'])
                        mord = []
                        for my_model_name in my_app_models:
                            for model_def in model_list:
                               if model_def['object_name'] == my_model_name:
                                   mord.append(model_def)
                                   model_list.remove(model_def)
                                   break
                        # mord[len(mord):] = model_list
                        ordered.append({'app_url': app_def['app_url'], 'models': mord, 'name': app_def['name']})
                        app_list.remove(app_def)
                        break
            ordered[len(ordered):] = app_list
            context['app_list'] = ordered
        return ''

def app_order(parser, token):
    return AppOrderNode()
var = register.tag(app_order)

