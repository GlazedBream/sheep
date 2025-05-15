from django.urls import path
from .views import TimelineCreateView, EventUpdateView, EventTimelineView, EventCreateView, TimelineDetailView

urlpatterns = [
    path('create/', EventCreateView.as_view(), name='event_create'),
    path('<int:event_id>/', EventUpdateView.as_view(), name='event_update'),
    path('timeline/', TimelineCreateView.as_view(), name='timeline_create'),
    path('timeline/<int:timeline_id>/events/', EventTimelineView.as_view(), name='timeline_events'),
    path("timeline/<str:date_str>/", TimelineDetailView.as_view(), name="timeline-detail"),
]
