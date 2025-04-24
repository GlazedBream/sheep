from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/auth/", include("auth.urls")),
    path("api/users/", include("users.urls")),
    path("api/diaries/", include("diaries.urls")),
    path("api/events/", include("diaries.urls")),
    path("api/logs/", include("logs.urls")),
]
