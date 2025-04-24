from django.urls import path
from .views import (
    SendCodeView,
    VerifyCodeView,
    SignupView,
    TokenObtainPairView,
    TokenRefreshView,
)

urlpatterns = [
    path("send-code/", SendCodeView.as_view(), name="send_code"),
    path("verify-code/", VerifyCodeView.as_view(), name="verify_code"),
    path("signup/", SignupView.as_view(), name="signup"),
    path("token/", TokenObtainPairView.as_view(), name="token_obtain_pair"),
    path("token/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    # path("social-login/", views.SocialLoginView.as_view(), name="social_login"),
]
