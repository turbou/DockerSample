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
from . import views

#admin.site.site_title = 'ContrastSecurity統合管理'
#admin.site.site_header = 'ContrastSecurity統合管理サイト'
#admin.site.index_title = 'メニュー'
admin.site.site_title = 'ContrastSecurity Integration Management'
admin.site.site_header = 'ContrastSecurity Integration Management Site'
admin.site.index_title = 'Menu'

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/token/', obtain_jwt_token),
    path('api/token/verify/', verify_jwt_token),
    path('api/token/refresh/', refresh_jwt_token),
    path('hook/', views.hook, name='hook'),    # from TeamServer
    path('vote/', views.vote, name='vote'),    # from TeamServer for Backlog
    #path('vote2/', views.vote2, name='vote2'), # from TeamServer for Gitlab
    path('vote3/', views.vote3, name='vote3'), # from TeamServer for Google Chat
    path('gitlab/', views.gitlab, name='gitlab'), # from Gitlab webhook
] + static('static/', document_root=settings.STATIC_ROOT)

