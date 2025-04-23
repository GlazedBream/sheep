from django.db import models
from django.contrib.auth.models import (
    AbstractBaseUser,
    BaseUserManager,
    PermissionsMixin,
)


class UserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError("이메일은 필수입니다.")
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        return self.create_user(email, password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    GENDER_CHOICES = [
        ("male", "남성"),
        ("female", "여성"),
    ]

    user_id = models.AutoField(primary_key=True)
    email = models.EmailField(max_length=255, unique=True)
    password = models.CharField(max_length=128)
    name = models.CharField(max_length=150, blank=True, null=True)
    gender = models.CharField(
        max_length=6, choices=GENDER_CHOICES, blank=True, null=True
    )
    age = models.PositiveIntegerField(blank=True, null=True)

    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    objects = UserManager()

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = []

    def __str__(self):
        return self.email
