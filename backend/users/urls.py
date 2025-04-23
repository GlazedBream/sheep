from django.urls import path
from . import views

urlpatterns = [
    path("me/daily-status/", views.DailyStatusView.as_view(), name="daily_status"),
    path("me/profile/", views.ProfileView.as_view(), name="user_profile"),
]
