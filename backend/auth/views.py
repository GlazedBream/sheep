from django.conf import settings
from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.core.mail import send_mail
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.exceptions import TokenError
from drf_spectacular.utils import extend_schema, OpenApiExample
from .serializers import (
    SignupSerializer,
    VerifyCodeSerializer,
    SendCodeSerializer,
    TokenObtainPairSerializer,
    TokenRefreshSerializer,
    SocialLoginSerializer,
)
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

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
        request=serializer_class,
        responses={
            201: {
                "description": "회원가입 성공",
                "content": {
                    "application/json": {
                        "example": {
                            "message": "회원가입이 성공적으로 완료되었습니다."
                        }
                    }
                },
            },
            400: {
                "description": "유효성 검사 실패",
                "content": {
                    "application/json": {
                        "example": {
                            "message": "회원가입에 실패했습니다.",
                            "errors": {
                                "password": ["비밀번호가 일치하지 않습니다."],
                                "email": ["이미 사용 중인 이메일입니다."],
                                "user_name": ["이미 사용 중인 사용자 이름입니다."],
                                "birthday": ["올바른 날짜 형식이 아닙니다."],
                                "gender": ["올바른 성별 값이 아닙니다. 허용되는 값: 'male', 'female'"]
                            }
                        }
                    }
                },
            },
        },
    )
    def post(self, request):
        serializer = self.serializer_class(data=request.data)
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
        request=serializer_class,
        responses={
            200: {
                "description": "인증번호 발송 성공",
                "content": {
                    "application/json": {
                        "example": {
                            "message": "인증번호가 발송되었습니다. 이메일을 확인해주세요.",
                            "email": "user@example.com"
                        }
                    }
                },
            },
            400: {
                "description": "이메일 형식 오류",
                "content": {
                    "application/json": {
                        "example": {
                            "message": "이메일 형식이 올바르지 않습니다.",
                            "errors": {
                                "email": ["올바른 이메일 형식이 아닙니다."]
                            }
                        }
                    }
                },
            },
        },
    )
    def post(self, request):
        serializer = self.serializer_class(data=request.data)
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
        description="인증번호 확인",
        request=serializer_class,
        responses={
            200: {
                "description": "인증번호 확인 성공",
                "content": {
                    "application/json": {
                        "example": {
                            "message": "인증번호가 일치합니다. 이메일 인증이 완료되었습니다.",
                            "email": "user@example.com",
                            "verified": True
                        }
                    }
                },
            },
            400: {
                "description": "인증번호 불일치",
                "content": {
                    "application/json": {
                        "example": {
                            "message": "인증번호가 일치하지 않습니다.",
                            "errors": {
                                "code": ["인증번호가 일치하지 않습니다. 6자리 숫자를 입력해주세요."]
                            }
                        }
                    }
                },
            },
        },
    )
    def post(self, request):
        serializer = self.serializer_class(data=request.data)
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
        request=serializer_class,
        responses={
            200: OpenApiExample(
                "소셜 로그인 성공",
                value={"message": "Social login successful."},
            )
        },
    )
    def post(self, request):
        serializer = self.serializer_class(data=request.data)
        if serializer.is_valid():
            return Response(serializer.validated_data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# JWT 토큰 발급
class CustomTokenObtainPairView(TokenObtainPairView):
    """
    API-A005: JWT 로그인 & 토큰 발급
    POST /api/auth/token/

    사용자 인증 정보를 검증하고 JWT 토큰을 발급합니다.
    """
    serializer_class = TokenObtainPairSerializer

    @extend_schema(
        description="사용자 인증 정보를 검증하고 JWT 토큰을 발급합니다.",
        request=serializer_class,
        responses={
            200: {
                "description": "JWT 토큰 발급 성공",
                "content": {
                    "application/json": {
                        "example": {
                            "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
                            "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
                        }
                    }
                },
            },
            401: {
                "description": "인증 오류",
                "content": {
                    "application/json": {
                        "example": {
                            "detail": "No active account found with the given credentials",
                            "code": "no_active_account"
                        }
                    },
                },
            },
            400: {
                "description": "유효성 검사 실패",
                "content": {
                    "application/json": {
                        "example": {
                            "detail": "Invalid email or password",
                            "code": "invalid_credentials"
                        }
                    },
                },
            }
        },
    )
    def post(self, request, *args, **kwargs):
        serializer = self.serializer_class(data=request.data)
        if serializer.is_valid():
            return Response(serializer.validated_data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    """
    API-A005: JWT 로그인 & 토큰 발급
    POST /api/auth/token/
    """

    serializer_class = TokenObtainPairSerializer

    @extend_schema(
        description="JWT 토큰 발급",
        request=serializer_class,
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
    def post(self, request, *args, **kwargs):
        serializer = self.serializer_class(data=request.data)
        if serializer.is_valid():
            return Response(serializer.validated_data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# JWT 토큰 갱신
class CustomTokenRefreshView(TokenRefreshView):
    """
    API-A006: 토큰 재발급
    POST /api/auth/token/refresh/

    만료된 JWT 접근 토큰을 새로운 토큰으로 교체합니다.
    """
    serializer_class = TokenRefreshSerializer

    @extend_schema(
        description="만료된 JWT 접근 토큰을 새로운 토큰으로 교체합니다.",
        request=serializer_class,
        responses={
            200: {
                "description": "토큰 갱신 성공",
                "content": {
                    "application/json": {
                        "example": {
                            "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
                        }
                    }
                },
            },
            401: {
                "description": "토큰 만료",
                "content": {
                    "application/json": {
                        "example": {
                            "detail": "Token is invalid or expired",
                            "code": "token_expired"
                        }
                    },
                },
            },
            400: {
                "description": "유효성 검사 실패",
                "content": {
                    "application/json": {
                        "example": {
                            "detail": "Invalid refresh token",
                            "code": "invalid_token"
                        }
                    },
                },
            }
        },
    )
    def post(self, request, *args, **kwargs):
        serializer = self.serializer_class(data=request.data)
        try:
            if serializer.is_valid():
                return Response(serializer.validated_data, status=status.HTTP_200_OK)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        except TokenError as e:
            return Response(
                {"detail": str(e), "code": "token_expired"},
                status=status.HTTP_401_UNAUTHORIZED
            )
    """
    API-A006: 토큰 재발급
    POST /api/auth/token/refresh/
    """
    serializer_class = TokenRefreshSerializer

    @extend_schema(
        description="JWT 토큰 갱신",
        request=serializer_class,
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
                    },
                },
            },
        },
    )
    def post(self, request, *args, **kwargs):
        serializer = self.serializer_class(data=request.data)
        if serializer.is_valid():
            return Response(serializer.validated_data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
