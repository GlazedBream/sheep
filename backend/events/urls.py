from django.urls import path
from . import views

urlpatterns = [
    path("<int:event_id>/", views.EventUpdateView.as_view(), name="event-update"),
]
