from django.urls import path
from .views import (
    DiaryCreateView,
    DiaryByMonthView,
    DiaryDetailView,
)

urlpatterns = [
    path("", DiaryCreateView.as_view(), name="diary_create"),
    path("dates/", DiaryByMonthView.as_view(), name="diary-by-month"),
    path("<str:diary_date>/", DiaryDetailView.as_view(), name="diary_detail"),
]
