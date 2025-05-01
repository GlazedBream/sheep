from django.urls import path
from .views import EventCreateView, EventUpdateView, EventTimelineView

urlpatterns = [
    path("", EventCreateView.as_view(), name="event_create"),
    path("timeline/", EventTimelineView.as_view(), name="event_timeline"),
    path("<int:event_id>/", EventUpdateView.as_view(), name="event_detail"),
]
