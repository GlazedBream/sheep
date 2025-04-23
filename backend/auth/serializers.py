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

    class Meta:
        model = get_user_model()
        fields = ["email", "password", "password2"]

    def validate(self, attrs):
        if attrs["password"] != attrs["password2"]:
            raise serializers.ValidationError("Passwords must match.")
        return attrs

    def create(self, validated_data):
        user = get_user_model().objects.create_user(
            email=validated_data["email"], password=validated_data["password"]
        )
        return user


class SendCodeSerializer(serializers.Serializer):
    email = serializers.EmailField()


class VerifyCodeSerializer(serializers.Serializer):
    email = serializers.EmailField()
    code = serializers.IntegerField(
        validators=[MinValueValidator(100000), MaxValueValidator(999999)]
    )
