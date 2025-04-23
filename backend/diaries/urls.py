from django.urls import path
from . import views

urlpatterns = [
    path("", views.DiaryListCreateView.as_view(), name="diary_list_create"),
    path("<int:pk>/", views.DiaryDetailView.as_view(), name="diary_detail"),
]
