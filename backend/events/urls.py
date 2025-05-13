from django.urls import path
from .views import TimelineCreateView, EventUpdateView, EventTimelineView, EventCreateView

urlpatterns = [
    path('create/', EventCreateView.as_view(), name='event_create'),
    path('<int:event_id>/', EventUpdateView.as_view(), name='event_update'),
    path('timeline/', TimelineCreateView.as_view(), name='timeline_create'),
    path('timeline/<int:timeline_id>/events/', EventTimelineView.as_view(), name='timeline_events'),
]
