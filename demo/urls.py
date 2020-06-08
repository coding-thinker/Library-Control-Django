"""demo URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/3.0/topics/http/urls/
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
from welcome import views as welcomeviews
from login import views as loginviews
from reader import views as readerviews
from librarian import views as librarianviews

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', welcomeviews.default),
    path('login/', loginviews.default),
    path('reader/<str:user>', readerviews.default),
    path('librarian/<str:user>', librarianviews.default),
]
