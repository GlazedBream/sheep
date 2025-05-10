from pathlib import Path

import os
from datetime import timedelta
from dotenv import load_dotenv

load_dotenv()

EMAIL_BACKEND = os.getenv("EMAIL_BACKEND")
EMAIL_HOST = os.getenv("EMAIL_HOST")
EMAIL_PORT = int(os.getenv("EMAIL_PORT"))
EMAIL_HOST_USER = os.getenv("EMAIL_HOST_USER")
EMAIL_HOST_PASSWORD = os.getenv("EMAIL_HOST_PASSWORD")
EMAIL_USE_TLS = os.getenv("EMAIL_USE_TLS") == "True"
DEFAULT_FROM_EMAIL = os.getenv("DEFAULT_FROM_EMAIL")

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent


# Quick-start development settings - unsuitable for production
# See https://docs.djangoproject.com/en/4.2/howto/deployment/checklist/

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = "django-insecure-9em7$&w2qe-thguuz_echxiezewst%e7)xmeo5a$53jrmex%zc"

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True

ALLOWED_HOSTS = ["*"]


# Application definition

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "rest_framework",
    "rest_framework_simplejwt",
    "corsheaders",  # corsheaders
    "drf_spectacular",  # API documentation
    "users",
    "diaries",
    "events",
    "logs",
    "galleries",
    "stores",
]

MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",  # corsheaders
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]


ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"


# Database
# https://docs.djangoproject.com/en/4.2/ref/settings/#databases

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.mysql",
        "NAME": os.getenv("DB_NAME"),
        "USER": os.getenv("DB_USER"),
        "PASSWORD": os.getenv("DB_PASSWORD"),
        "HOST": os.getenv("DB_HOST", "localhost"),
        "PORT": os.getenv("DB_PORT", "3306"),
    }
}

# AWS S3 설정
AWS_ACCESS_KEY_ID = os.getenv("AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = os.getenv("AWS_SECRET_ACCESS_KEY")
AWS_STORAGE_BUCKET_NAME = os.getenv("AWS_STORAGE_BUCKET_NAME")
AWS_S3_REGION_NAME = os.getenv("AWS_S3_REGION_NAME")
AWS_S3_CUSTOM_DOMAIN = os.getenv("AWS_S3_CUSTOM_DOMAIN")
AWS_DEFAULT_ACL = os.getenv("AWS_DEFAULT_ACL")
AWS_S3_FILE_OVERWRITE = os.getenv("AWS_S3_FILE_OVERWRITE", False)
AWS_QUERYSTRING_AUTH = os.getenv("AWS_QUERYSTRING_AUTH", False)

# S3 업로드 설정
AWS_S3_OBJECT_PARAMETERS = {
    "CacheControl": "max-age=86400",
}


# Password validation
# https://docs.djangoproject.com/en/4.2/ref/settings/#auth-password-validators

AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.CommonPasswordValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.NumericPasswordValidator",
    },
]


# Internationalization
# https://docs.djangoproject.com/en/4.2/topics/i18n/

LANGUAGE_CODE = "ko-kr"

TIME_ZONE = "Asia/Seoul"

USE_I18N = True  # 국제화
USE_L10N = True  # 현지화

USE_TZ = True  # API서버로만 쓰는 경우 False 사용 추천


# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/4.2/howto/static-files/

STATIC_URL = "static/"
STATIC_ROOT = os.path.join(BASE_DIR, "staticfiles")

# Default primary key field type
# https://docs.djangoproject.com/en/4.2/ref/settings/#default-auto-field

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

# CORS
if DEBUG:
    CORS_ALLOW_ALL_ORIGINS = True  # corsheaders
else:
    CORS_ALLOW_ALL_ORIGINS = False
    CORS_ALLOWED_ORIGINS = ["https://your-domain-example.com"]  # 배포 환경 도메인 추가

# Django REST Framework
if DEBUG:
    REST_FRAMEWORK = {
        "DEFAULT_PERMISSION_CLASSES": [
            "rest_framework.permissions.AllowAny",  # AllowAny, IsAuthenticated, DjangoModelPermissionsOrAnonReadOnly
        ],
        "DEFAULT_AUTHENTICATION_CLASSES": [
            "rest_framework_simplejwt.authentication.JWTAuthentication",
        ],
        "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
    }
else:
    REST_FRAMEWORK = {
        "DEFAULT_PERMISSION_CLASSES": [
            "rest_framework.permissions.IsAuthenticated",  # AllowAny, IsAuthenticated, DjangoModelPermissionsOrAnonReadOnly
        ],
        "DEFAULT_AUTHENTICATION_CLASSES": [
            "rest_framework_simplejwt.authentication.JWTAuthentication",
        ],
        "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
    }

SPECTACULAR_SETTINGS = {
    "TITLE": "Sheep Diary API",
    "DESCRIPTION": "API documentation for Sheep Diary project.",
    "VERSION": "1.0.0",
    "SERVE_INCLUDE_SCHEMA": False,
}


# send_code, verify_code 설정 추가 필요

CACHES = {
    "default": {
        "BACKEND": "django_redis.cache.RedisCache",
        "LOCATION": os.getenv(
            "REDIS_LOCATION", "redis://127.0.0.1:6379/1"
        ),  # DB 1 사용 (기본 0과 분리)
        "OPTIONS": {
            "CLIENT_CLASS": "django_redis.client.DefaultClient",
        },
    }
}

# 인증번호 유효시간(초)
VERIFICATION_CODE_EXPIRE = 300

AUTH_USER_MODEL = "users.User"

# JWT 수명 설정
SIMPLE_JWT = {
    "USER_ID_FIELD": "user_id",  # 기본값은 'id'
    "USER_ID_CLAIM": "user_id",
    # ✅ 개발 단계에서는 access token을 사실상 무한정 유효하게 설정
    # ❗ 배포 전 짧은 시간(timedelta(minutes=10))으로 되돌릴 것
    "ACCESS_TOKEN_LIFETIME": timedelta(days=3650),  # 개발용: 10년
    # ✅ refresh token도 매우 긴 시간으로 설정해 로그인 반복 방지
    # ❗ 배포 전 timedelta(days=14) 수준으로 조정 필요
    "REFRESH_TOKEN_LIFETIME": timedelta(days=3650),  # 개발용: 10년
    "ROTATE_REFRESH_TOKENS": False,  # 개발 중에는 관리 편의를 위해 비활성화, 배포 시 True
    "BLACKLIST_AFTER_ROTATION": True,  # 보안 테스트를 위해 활성화 유지 가능
}
