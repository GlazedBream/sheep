from django.urls import path
from .views import (
    DiaryCreateView,
    DiaryByMonthView,
    DiaryDetailView,
    DiarySuggestionView,
    TestPostView,
)

urlpatterns = [
    path("", DiaryCreateView.as_view(), name="diary_create"),
    path("dates/", DiaryByMonthView.as_view(), name="diary_by_month"),
    path("suggestions/", DiarySuggestionView.as_view(), name="diary_suggestions"),
    path("<str:diary_date>/", DiaryDetailView.as_view(), name="diary_detail"),
]
