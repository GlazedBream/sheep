from django.urls import path
from .views import DailyStatusView, UserProfileView

urlpatterns = [
    path("me/daily-status/", DailyStatusView.as_view(), name="daily_status"),
    path("me/profile/", UserProfileView.as_view(), name="user_profile"),
]
