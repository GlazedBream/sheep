from django.urls import path
from .views import SearchLogListCreateView

urlpatterns = [
    path("api/search-logs/", SearchLogListCreateView.as_view(), name="search_logs"),
]
