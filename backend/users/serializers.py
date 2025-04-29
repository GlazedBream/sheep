from rest_framework import serializers
from .models import User, Agreement, UserProfilePicture, UserAlarmSetting
from diaries.models import Diary
from django.db import models
from drf_spectacular.utils import extend_schema_field


class DailyStatusSerializer(serializers.Serializer):
    is_authenticated = serializers.BooleanField()
    today_date = serializers.DateField()
    emotion = serializers.CharField(allow_null=True)
    diary_exists = serializers.BooleanField()


class UserProfileResponseSerializer(serializers.Serializer):
    user_id = serializers.IntegerField()
    user_name = serializers.CharField()
    email = serializers.EmailField()
    profile_image_url = serializers.URLField()
    joined_date = serializers.DateField()

    @extend_schema_field(serializers.IntegerField)
    def get_diary_count(self, obj):
        return (
            Diary.objects.filter(user=obj)
            .annotate(date_only=models.DateTimeField())
            .values("diary_date__date")
            .distinct()
            .count()
        )

    @extend_schema_field(serializers.DateField)
    def get_last_diary_date(self, obj):
        last_diary = Diary.objects.filter(user=obj).order_by("-diary_date").first()
        return last_diary.diary_date if last_diary else None
