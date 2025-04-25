from django.urls import path
from .views import EventUpdateView, EventTimelineView

urlpatterns = [
    path("<int:event_id>/", EventUpdateView.as_view(), name="event-update"),
    path("timeline/", EventTimelineView.as_view(), name="event-timeline"),
]
