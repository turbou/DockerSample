"""relay_django URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/2.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path
from django.conf import settings
from django.conf.urls.static import static
from rest_framework_jwt.views import obtain_jwt_token, verify_jwt_token, refresh_jwt_token
from django.utils.translation import gettext_lazy as _
from . import views

#admin.site.site_title = 'ContrastSecurity統合管理'
#admin.site.site_header = 'ContrastSecurity統合管理サイト'
#admin.site.index_title = 'メニュー'
admin.site.site_title = _('Contrast Integration Management')
admin.site.site_header = _('Contrast Integration Management')
admin.site.index_title = _('Menu')

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/token/', obtain_jwt_token),
    path('api/token/verify/', verify_jwt_token),
    path('api/token/refresh/', refresh_jwt_token),
    path('hook/', views.hook, name='hook'),    # from TeamServer
    path('backlog/', views.backlog, name='backlog'), # from Backlog webhook
    path('gitlab/', views.gitlab, name='gitlab'), # from Gitlab webhook
] + static('static/', document_root=settings.STATIC_ROOT)

