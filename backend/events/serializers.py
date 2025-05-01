from rest_framework import serializers
from galleries.models import Location
from diaries.models import Diary
from .models import Event, Memo, Keyword, EventKeyword
import os


class MemoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Memo
        fields = ["memo_content"]


class KeywordSerializer(serializers.ModelSerializer):
    class Meta:
        model = Keyword
        fields = ["content", "source_type"]


class EventSerializer(serializers.ModelSerializer):
    if os.getenv("USE_GEOLOCATION_BYPASS", "False").lower() == "true":
        longitude = serializers.FloatField(required=False, allow_null=True)
        latitude = serializers.FloatField(required=False, allow_null=True)
    else:
        location_id = serializers.PrimaryKeyRelatedField(
            queryset=Location.objects.all()
        )

    diary_id = serializers.PrimaryKeyRelatedField(
        queryset=Diary.objects.all(), required=False, allow_null=True
    )
    title = serializers.CharField(max_length=255, required=False, allow_null=True)
    start_time = serializers.DateTimeField(required=True)
    memos = MemoSerializer(many=True)  # read_only 제거
    keywords = KeywordSerializer(many=True, required=False)

    class Meta:
        model = Event
        if os.getenv("USE_GEOLOCATION_BYPASS", "False").lower() == "true":
            fields = [
                "event_id",
                "diary_id",
                "title",
                "longitude",
                "latitude",
                "start_time",
                "event_emotion_id",
                "weather",
                "is_selected_event",
                "memos",
                "keywords",
            ]
        else:
            fields = [
                "event_id",
                "diary_id",
                "title",
                "location_id",
                "start_time",
                "event_emotion_id",
                "weather",
                "is_selected_event",
                "memos",
                "keywords",
            ]

    def create(self, validated_data):
        memos_data = validated_data.pop("memos", [])
        keywords_data = validated_data.pop("keywords", [])
        user = self.context["request"].user

        # Event 생성
        event = Event.objects.create(
            user_id=user,
            start_time=validated_data["start_time"],
            event_emotion_id=validated_data.get("event_emotion_id", 1),
            weather=validated_data.get("weather", "sunny"),
            is_selected_event=validated_data.get("is_selected_event", False),
            longitude=validated_data.get("longitude", None),
            latitude=validated_data.get("latitude", None),
        )

        # Memo 생성
        for memo_data in memos_data:
            Memo.objects.create(event=event, **memo_data)

        # Keyword 생성
        for keyword_data in keywords_data:
            keyword, created = Keyword.objects.get_or_create(
                content=keyword_data["content"],
                source_type=keyword_data.get("source_type", Keyword.FROM_USER),
            )
            EventKeyword.objects.create(
                event=event, keyword=keyword, is_selected_keyword=False
            )

        return event

    def update(self, instance, validated_data):
        memos_data = validated_data.pop("memos", None)

        # Event 본체 업데이트
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        # Memo 업데이트
        if memos_data is not None:
            instance.memos.all().delete()  # 기존 메모 삭제 (필요에 따라 수정 전략 변경 가능)
            for memo_data in memos_data:
                Memo.objects.create(event=instance, **memo_data)

        return instance
