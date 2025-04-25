from django.db import models
from django.conf import settings
from django.contrib.auth.models import (
    AbstractBaseUser,
    BaseUserManager,
    PermissionsMixin,
)
from django.utils import timezone
from datetime import date


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
    user_name = models.CharField(max_length=150, blank=True, null=True)
    gender = models.CharField(
        max_length=6, choices=GENDER_CHOICES, blank=True, null=True
    )
    birthday = models.DateField(blank=True, null=True)
    joined_date = models.DateTimeField(default=timezone.now)

    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    is_superuser = models.BooleanField(default=False)

    objects = UserManager()

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = []

    @property
    def id(self):
        return self.user_id

    @property
    def age(self):
        if self.birthday:
            today = date.today()
            return (
                today.year
                - self.birthday.year
                - ((today.month, today.day) < (self.birthday.month, self.birthday.day))
            )
        return None

    @property
    def age_group(self):
        a = self.age
        if a is None:
            return None
        elif a < 20:
            return "10대 이하"
        elif a < 30:
            return "20대"
        elif a < 40:
            return "30대"
        elif a < 50:
            return "40대"
        else:
            return "50대 이상"

    def __str__(self):
        return self.email


class Agreement(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    gps_agreement = models.BooleanField(default=False)
    personal_info = models.BooleanField(default=False)
    terms = models.BooleanField(default=False)
    updated_at = models.DateTimeField(auto_now=True)  # 마지막 수정 시간

    def __str__(self):
        return f"Agreement for {self.user.email}"


class UserProfilePicture(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, primary_key=True
    )
    profile_picture_url = models.URLField(max_length=255, blank=True)

    def __str__(self):
        return f"{self.user.name}'s Profile Picture"


class UserAlarmSetting(models.Model):
    class AlarmType(models.TextChoices):
        DAILY_SUMMARY = "daily_summary", "Daily Summary"
        WRITING_REMINDER = "writing_reminder", "Writing Reminder"
        CUSTOM = "custom", "Custom"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="alarm_settings",
    )
    alarm_type = models.CharField(max_length=20, choices=AlarmType.choices)
    alarm_time = models.TimeField()
    repeat_days = models.CharField(max_length=27)  # 예: 'Mon,Wed,Fri'
    is_enabled = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.user.name}'s {self.alarm_type} alarm"
