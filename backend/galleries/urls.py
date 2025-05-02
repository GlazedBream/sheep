from django.urls import path
from .views import GetPresignedUrlView, NotifyUploadView, ConfirmImageView

app_name = "galleries"

urlpatterns = [
    path("get-presigned-url/", GetPresignedUrlView.as_view(), name="get_presigned_url"),
    path("notify-upload/", NotifyUploadView.as_view(), name="notify_upload"),
    path("confirm-image/", ConfirmImageView.as_view(), name="confirm_image"),
]
