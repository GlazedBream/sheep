from django.urls import path
from .views import (
    DiaryCreateView,
    DiaryByMonthView,
    DiaryDetailView,
    EventUpdateView,
    EventTimelineView,
)

urlpatterns = [
    # /api/diaries/
    path("", DiaryCreateView.as_view(), name="diary_create"),
    path("dates/", DiaryByMonthView.as_view(), name="diary-by-month"),
    path("<int:diary_id>/", DiaryDetailView.as_view(), name="diary_detail"),
    # /api/events/
    path("<int:event_id>/", EventUpdateView.as_view(), name="event-update"),
    path("events/", EventTimelineView.as_view(), name="event-timeline"),
]
