from django.urls import path
from .views import (
    DiaryCreateView,
    DiaryByMonthView,
    DiaryDetailView,
    DiarySuggestionView,
    TaskStatusView,
)

urlpatterns = [
    path("", DiaryCreateView.as_view(), name="diary_create"),
    path("dates/", DiaryByMonthView.as_view(), name="diary-by-month"),
    path("<str:diary_date>/", DiaryDetailView.as_view(), name="diary_detail"),
    path('suggestions/', DiarySuggestionView.as_view(), name='diary-suggest'),
    path('suggestions/tasks/<str:task_id>/', TaskStatusView.as_view(), name='task-status'),
]
