from rest_framework import serializers
from .models import User, Agreement, UserProfilePicture, UserAlarmSetting
from diaries.models import Diary


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
    diary_count = serializers.SerializerMethodField()
    last_diary_date = serializers.SerializerMethodField()

    def get_diary_count(self, obj):
        # 날짜만 기준으로 중복 제거하여 작성한 날짜 수 계산
        return (
            Diary.objects.filter(user=obj)
            .annotate(date_only=serializers.DateTimeField().to_representation)
            .values("diary_date__date")  # DateTimeField에서 날짜 부분만
            .distinct()
            .count()
        )

    def get_last_diary_date(self, obj):
        last_diary = Diary.objects.filter(user=obj).order_by("-diary_date").first()
        return last_diary.diary_date if last_diary else None
