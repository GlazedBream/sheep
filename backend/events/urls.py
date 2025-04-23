from django.urls import path
from .views import EventListByDateRangeAPIView

urlpatterns = [
    path(
        "",
        EventListByDateRangeAPIView.as_view(),
        name="event-list-by-date-range",
    ),
]
