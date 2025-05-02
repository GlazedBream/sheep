from django.urls import path
from .views import TimelineCreateView, EventUpdateView, EventTimelineView

urlpatterns = [
    path("<int:event_id>/", EventUpdateView.as_view(), name="event-update"),
    path("timeline/", TimelineCreateView.as_view(), name="timeline-create"),
    path(
        "timeline/<int:timeline_id>/",
        EventTimelineView.as_view(),
        name="event-timeline",
    ),
]
