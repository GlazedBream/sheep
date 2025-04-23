from django.conf import settings
from django.shortcuts import render
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from .serializers import SignupSerializer, VerifyCodeSerializer, SendCodeSerializer
from django.core.cache import cache  # Redis 캐시

# get_user_model은 향후 get_user_model().objects.get(email=email), 사용자 생성 삭제, 커스텀 유저모델 속성 접근 등에서 사용
from django.contrib.auth import get_user_model, authenticate

from django.core.mail import send_mail
import random


# 회원가입 요청
class SignupView(APIView):
    def post(self, request):
        serializer = SignupSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            return Response(
                {"message": "User created successfully."},
                status=status.HTTP_201_CREATED,
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# 인증번호 발송
class SendCodeView(APIView):
    def post(self, request):
        serializer = SendCodeSerializer(data=request.data)
        if serializer.is_valid():
            # 인증번호 생성 및 발송
            code = random.randint(100000, 999999)
            email = serializer.validated_data["email"]
            send_mail(
                "쉽다이어리 인증 코드입니다",
                f"안녕하세요!\n쉽다이어리 회원가입 인증번호는 [{code}]입니다.\n5분 내로 입력해주세요.\n감사합니다.",
                "sheep.diary.test@gmail.com",
                [email],
            )
            cache.set(
                f"verify:{email}", code, timeout=settings.VERIFICATION_CODE_EXPIRE
            )
            return Response(
                {"message": "인증번호가 이메일로 전송되었습니다."},
                status=status.HTTP_200_OK,
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# 인증번호 확인
class VerifyCodeView(APIView):
    def post(self, request):
        serializer = VerifyCodeSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data["email"]
            input_code = serializer.validated_data["code"]
            stored_code = cache.get(f"verify:{email}")  # Redis에 저장된 코드 조회
            if stored_code is None:
                return Response(
                    {"message": "인증번호가 만료되었습니다. 다시 요청해주세요."},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            if str(stored_code) == str(input_code):
                return Response(
                    {"message": "인증이 완료되었습니다."}, status=status.HTTP_200_OK
                )
            else:
                return Response(
                    {"message": "인증번호가 일치하지 않습니다."},
                    status=status.HTTP_400_BAD_REQUEST,
                )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# 소셜 로그인 처리
class SocialLoginView(APIView):
    def post(self, request):
        # 여기서 Google OAuth나 Facebook OAuth 등 소셜 로그인 처리 로직을 구현합니다.
        return Response(
            {"message": "Social login successful."}, status=status.HTTP_200_OK
        )


# JWT 토큰 발급 (Django Rest Framework Simple JWT 사용)
class TokenObtainPairView(APIView):
    def post(self, request):
        # 사용자 인증 로직을 처리하고, JWT 토큰을 발급하는 부분입니다.
        user = authenticate(
            username=request.data["username"], password=request.data["password"]
        )
        if user is not None:
            refresh = RefreshToken.for_user(user)
            return Response(
                {
                    "access": str(refresh.access_token),
                    "refresh": str(refresh),
                }
            )
        return Response(
            {"detail": "Invalid credentials."}, status=status.HTTP_401_UNAUTHORIZED
        )


# 토큰 갱신
class TokenRefreshView(APIView):
    def post(self, request):
        # 클라이언트에서 제공한 refresh token을 사용해 새 토큰을 발급합니다.
        refresh_token = request.data.get("refresh")
        try:
            refresh = RefreshToken(refresh_token)
            return Response(
                {
                    "access": str(refresh.access_token),
                }
            )
        except Exception as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)
