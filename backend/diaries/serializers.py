from rest_framework import serializers
from .models import Diary, Emotion, DiaryKeyword


class DiarySerializer(serializers.ModelSerializer):
    class Meta:
        model = Diary
        fields = [
            "diary_id",
            "user",
            "title",
            "final_text",
            "emotion",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "user", "created_at", "updated_at"]
