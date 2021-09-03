import os

from celery import Celery

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "relay_django.settings")

app = Celery("relay_django")
app.config_from_object("django.conf:settings", namespace="CELERY")
app.autodiscover_tasks()

