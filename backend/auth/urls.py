from django.urls import path
from . import views

urlpatterns = [
    path("send-code/", views.SendCodeView.as_view(), name="send_code"),
    path("verify-code/", views.VerifyCodeView.as_view(), name="verify_code"),
    path("signup/", views.SignupView.as_view(), name="signup"),
    path("token/", views.TokenObtainPairView.as_view(), name="token_obtain_pair"),
    path("token/refresh/", views.TokenRefreshView.as_view(), name="token_refresh"),
    # path("social-login/", views.SocialLoginView.as_view(), name="social_login"),
]
