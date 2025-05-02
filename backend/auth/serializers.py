from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.core.validators import validate_email
from users.models import User
from django.contrib.auth.hashers import make_password
from django.core.validators import MinValueValidator, MaxValueValidator


class SignupSerializer(serializers.ModelSerializer):
    email = serializers.EmailField(validators=[validate_email])
    password = serializers.CharField(write_only=True)
    password2 = serializers.CharField(write_only=True)
    user_name = serializers.CharField(write_only=True)

    birthday = serializers.DateField(write_only=True, required=False)
    gender = serializers.ChoiceField(
        choices=[("male", "남성"), ("female", "여성")], write_only=True, required=False
    )

    class Meta:
        model = get_user_model()
        fields = ["email", "password", "password2", "user_name", "birthday", "gender"]

    def validate(self, attrs):
        if attrs["password"] != attrs["password2"]:
            raise serializers.ValidationError("비밀번호가 일치하지 않습니다.")
        if get_user_model().objects.filter(email=attrs["email"]).exists():
            raise serializers.ValidationError("이미 사용 중인 이메일입니다.")
        return attrs

    def create(self, validated_data):
        validated_data.pop("password2")
        user = get_user_model().objects.create_user(
            email=validated_data["email"],
            password=validated_data["password"],
            user_name=validated_data["user_name"],
            birthday=validated_data.get("birthday"),
            gender=validated_data.get("gender"),
        )
        return user


class SendCodeSerializer(serializers.Serializer):
    email = serializers.EmailField(
        help_text="인증번호를 받을 이메일 주소"
    )

    class Meta:
        extra_kwargs = {
            'email': {
                'example': 'user@example.com'
            }
        }

    class Meta:
        extra_kwargs = {
            'email': {
                'example': 'user@example.com'
            }
        }


class VerifyCodeSerializer(serializers.Serializer):
    email = serializers.EmailField(
        help_text="인증번호를 받은 이메일 주소"
    )
    code = serializers.IntegerField(
        validators=[MinValueValidator(100000), MaxValueValidator(999999)],
        help_text="6자리 숫자로 구성된 인증번호"
    )

    class Meta:
        extra_kwargs = {
            'email': {
                'example': 'user@example.com'
            },
            'code': {
                'example': 123456
            }
        }

    class Meta:
        extra_kwargs = {
            'email': {
                'example': 'user@example.com'
            },
            'code': {
                'example': 123456
            }
        }


class SocialLoginSerializer(serializers.Serializer):
    # 미구현
    pass

class TokenRefreshSerializer(serializers.Serializer):
    refresh = serializers.CharField(
        help_text="JWT 리프레시 토큰",
        style={'input_type': 'password'}
    )

    class Meta:
        extra_kwargs = {
            'refresh': {
                'example': 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...'
            }
        }

class TokenObtainPairSerializer(serializers.Serializer):
    email = serializers.EmailField(
        help_text="사용자 이메일"
    )
    password = serializers.CharField(
        help_text="사용자 비밀번호",
        style={'input_type': 'password'}
    )

    class Meta:
        extra_kwargs = {
            'email': {
                'example': 'user@example.com',
                'description': '사용자 이메일 주소'
            },
            'password': {
                'example': 'your_password',
                'description': '사용자 비밀번호'
            }
        }