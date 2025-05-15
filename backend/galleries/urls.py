from django.urls import path
from .views import PresignedURLView, NotifyUploadView, ConfirmImageView

app_name = "galleries"

urlpatterns = [
    path('get-presigned-url/', PresignedURLView.as_view(), name='get-presigned-url'),
    path('notify-upload/', NotifyUploadView.as_view(), name='notify-upload'),
    path('confirm-image/', ConfirmImageView.as_view(), name='confirm-image'),
]
