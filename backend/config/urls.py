from django.contrib import admin
from django.urls import path, include
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView, SpectacularRedocView

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/auth/", include("auth.urls")),
    path("api/users/", include("users.urls")),
    path("api/diaries/", include("diaries.urls")),
    path("api/events/", include("events.urls")),
    path("api/logs/", include("logs.urls")),
    path("api/galleries/", include("galleries.urls")),
    # stores 미구현
    # API Documentation
    path("api/schema/", SpectacularAPIView.as_view(), name="api-schema"),
    path("api/schema/swagger-ui/", SpectacularSwaggerView.as_view(url_name="api-schema"), name="api-swagger-ui"),
    path("api/schema/redoc/", SpectacularRedocView.as_view(url_name="api-schema"), name="api-redoc"),
]
