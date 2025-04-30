from django.conf import settings
from django.contrib.auth import get_user_model, authenticate
from django.core.cache import cache
from django.core.mail import send_mail
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.exceptions import TokenError
from drf_spectacular.utils import extend_schema, OpenApiParameter, OpenApiExample
from drf_spectacular.types import OpenApiTypes
from .serializers import (
    SignupSerializer,
    VerifyCodeSerializer,
    SendCodeSerializer,
    SocialLoginSerializer,
)
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

import random

User = get_user_model()


# 회원가입 요청
class SignupView(APIView):
    """
    API-A003: 회원가입 요청
    POST /api/auth/signup/
    """

    serializer_class = SignupSerializer

    @extend_schema(
        description="회원가입 요청",
        request=SignupSerializer,
        responses={
            201: {
                "description": "회원가입 성공",
                "content": {
                    "application/json": {
                        "example": {"message": "회원가입이 성공적으로 완료되었습니다."}
                    }
                },
            },
            400: {
                "description": "유효성 검사 실패",
                "content": {
                    "application/json": {
                        "example": {
                            "password": ["비밀번호가 일치하지 않습니다."],
                            "email": ["이미 사용 중인 이메일입니다."]
                        }
                    }
                },
            }
        }
    )
    def post(self, request):
        serializer = SignupSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(
                {"message": "회원가입이 완료되었습니다."},
                status=status.HTTP_201_CREATED,
            )
        return Response(
            {"message": "회원가입에 실패했습니다.", "errors": serializer.errors},
            status=status.HTTP_400_BAD_REQUEST,
        )


# 인증번호 발송
class SendCodeView(APIView):
    """
    API-A001: 인증번호 발송
    POST /api/auth/send-code/
    """

    serializer_class = SendCodeSerializer

    @extend_schema(
        description="이메일 인증 요청",
        request=SendCodeSerializer,
        responses={
            200: {
                "description": "인증번호 발송 성공",
                "content": {
                    "application/json": {
                        "example": {"message": "인증번호가 발송되었습니다."}
                    }
                },
            },
            400: {
                "description": "이메일 형식 오류",
                "content": {
                    "application/json": {
                        "example": {"email": ["올바른 이메일 형식이 아닙니다."]}
                    }
                },
            },
        },
    )
    def post(self, request):
        serializer = SendCodeSerializer(data=request.data)
        if serializer.is_valid():
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
    """
    API-A002: 인증번호 확인
    POST /api/auth/verify-code/
    """

    serializer_class = VerifyCodeSerializer

    @extend_schema(
        description="이메일 인증번호 확인",
        request=VerifyCodeSerializer,
        responses={
            200: {
                "description": "인증번호 확인 성공",
                "content": {
                    "application/json": {
                        "example": {"message": "인증번호가 일치합니다."}
                    }
                },
            },
            400: {
                "description": "인증번호 오류",
                "content": {
                    "application/json": {
                        "example": {"code": ["잘못된 인증번호입니다."]}
                    }
                },
            },
        },
    )
    def post(self, request):
        serializer = VerifyCodeSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data["email"]
            input_code = serializer.validated_data["code"]
            stored_code = cache.get(f"verify:{email}")

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
    """

    serializer_class = SocialLoginSerializer

    @extend_schema(
        description="소셜 로그인 처리(미구현)",
        responses={
            200: OpenApiExample(
                "소셜 로그인 성공",
                value={"message": "Social login successful."},
            )
        },
    )
    def post(self, request):
        return Response(
            {"message": "Social login successful."}, status=status.HTTP_200_OK
        )


# JWT 토큰 발급
class TokenObtainPairView(APIView):
    """
    API-A005: JWT 로그인 & 토큰 발급
    POST /api/auth/token/
    """

    serializer_class = TokenObtainPairSerializer

    @extend_schema(
        description="JWT 로그인 & 토큰 발급",
        request=TokenObtainPairSerializer,
        responses={
            200: {
                "description": "JWT 토큰 발급 성공",
                "content": {
                    "application/json": {
                        "example": {
                            "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
                            "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
                        }
                    }
                },
            },
            401: {
                "description": "인증 오류",
                "content": {
                    "application/json": {
                        "example": {
                            "detail": "No active account found with the given credentials"
                        }
                    }
                },
            },
        },
    )
    def post(self, request):
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
    """

    @extend_schema(
        description="JWT 토큰 갱신",
        request=None,
        responses={
            200: {
                "description": "토큰 갱신 성공",
                "content": {
                    "application/json": {
                        "example": {"access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."}
                    }
                },
            },
            401: {
                "description": "토큰 만료",
                "content": {
                    "application/json": {
                        "example": {"detail": "Token is invalid or expired"}
                    }
                },
            },
        },
    )
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
