from django.conf import settings
from django.shortcuts import render
from django.contrib.auth import get_user_model, authenticate
from django.core.cache import cache  # Redis 캐시
from django.core.mail import send_mail
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.exceptions import TokenError, InvalidToken
from .serializers import SignupSerializer, VerifyCodeSerializer, SendCodeSerializer

# get_user_model은 향후 get_user_model().objects.get(email=email), 사용자 생성 삭제, 커스텀 유저모델 속성 접근 등에서 사용


import random

User = get_user_model()


# 회원가입 요청
class SignupView(APIView):
    """
    API-A003: 회원가입 요청
    POST /api/auth/signup/

    응답 코드:
    - 201 Created: 정상 생성
    - 400 Bad Request: 형식 오류
    """

    def post(self, request):
        serializer = SignupSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(
                {"message": "회원가입이 완료되었습니다."},
                status=status.HTTP_201_CREATED,
            )

        # 유효성 검사 실패 시 message와 errors 필드를 포함한 응답 구조로 리턴
        return Response(
            {"message": "회원가입에 실패했습니다.", "errors": serializer.errors},
            status=status.HTTP_400_BAD_REQUEST,
        )


# 인증번호 발송
class SendCodeView(APIView):
    """
    API-A001: 인증번호 발송
    POST /api/auth/send-code/

    응답 코드:
    - 200 OK: 정상 응답
    - 400 Bad Request: 형식 오류
    - 429 Too Many Requests: 발송 횟수 제한 (미구현)
    """

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


class VerifyCodeView(APIView):
    """
    API-A002: 인증번호 발송
    POST /api/auth/verify-code/

    응답 코드:
    - 200 OK: 정상 응답
    - 400 Bad Request: 형식 오류
    """

    def post(self, request):
        serializer = VerifyCodeSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data["email"]
            input_code = serializer.validated_data["code"]
            stored_code = cache.get(f"verify:{email}")  # Redis에 저장된 코드 조회

            if stored_code is None:
                return Response(
                    {
                        "message": "인증번호가 만료되었습니다. 다시 요청해주세요.",
                        "errors": {
                            "verify_code": ["유효 시간이 초과된 인증 코드입니다."]
                        },
                    },
                    status=status.HTTP_400_BAD_REQUEST,
                )

            if str(stored_code) == str(input_code):
                return Response(
                    {"message": "인증이 완료되었습니다."}, status=status.HTTP_200_OK
                )
            else:
                return Response(
                    {
                        "message": "인증번호가 일치하지 않습니다.",
                        "errors": {
                            "verify_code": ["입력한 인증번호가 올바르지 않습니다."]
                        },
                    },
                    status=status.HTTP_400_BAD_REQUEST,
                )

        return Response(
            {"message": "요청 데이터에 오류가 있습니다.", "errors": serializer.errors},
            status=status.HTTP_400_BAD_REQUEST,
        )


# 소셜 로그인 처리
class SocialLoginView(APIView):
    """
    API-A004: 소셜 로그인 통합 처리
    POST /api/auth/social-login/
    (미구현)
    """

    def post(self, request):
        # 여기서 Google OAuth나 Facebook OAuth 등 소셜 로그인 처리 로직을 구현합니다.
        return Response(
            {"message": "Social login successful."}, status=status.HTTP_200_OK
        )


# JWT 토큰 발급 (Django Rest Framework Simple JWT 사용)
class TokenObtainPairView(APIView):
    """
    API-A005: JWT 로그인 & 토큰 발급
    POST /api/auth/token/

    응답 코드:
    - 200 OK: 정상 응답
    - 401 Unauthorized: 자격 오류
    """

    def post(self, request):
        # 사용자 인증 로직을 처리하고, JWT 토큰을 발급하는 부분입니다.
        user = authenticate(
            email=request.data["email"], password=request.data["password"]
        )
        if user is not None:
            refresh = RefreshToken.for_user(user)
            return Response(
                {
                    "access": str(refresh.access_token),
                    "refresh": str(refresh),
                },
                status=status.HTTP_200_OK,
            )
        return Response(
            {"message": "잘못된 자격 증명입니다."}, status=status.HTTP_401_UNAUTHORIZED
        )


# 토큰 갱신
class TokenRefreshView(APIView):
    """
    API-A006: 토큰 재발급
    POST /api/auth/token/refresh/

    응답 코드:
    - 200 OK: 정상 응답
    - 400 Bad Request: 형식 오류
    - 500 Server Error: 서버 오류
    """

    def post(self, request):
        refresh_token = request.data.get("refresh")

        if not refresh_token:
            return Response(
                {"message": "Refresh token이 제공되지 않았습니다."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            refresh = RefreshToken(refresh_token)
            return Response(
                {"access": str(refresh.access_token)},
                status=status.HTTP_200_OK,
            )
        except TokenError as e:
            return Response(
                {"message": "유효하지 않은 토큰입니다.", "details": str(e)},
                status=status.HTTP_400_BAD_REQUEST,
            )
        except Exception as e:
            return Response(
                {"message": "서버 오류가 발생했습니다.", "details": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )
