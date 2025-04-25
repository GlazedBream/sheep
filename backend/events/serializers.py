from rest_framework import serializers
from .models import Event, Keyword, Memo, EventKeyword


class MemoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Memo
        fields = ["memo_content"]


class EventSerializer(serializers.ModelSerializer):
    memos = MemoSerializer(many=True, read_only=True)  # 이벤트에 대한 메모를 포함

    class Meta:
        model = Event
        fields = [
            "event_id",
            "diary_id",
            "user_id",
            "location_id",
            "timestamp_st",
            "timestamp_end",
            "event_emotion",
            "weather",
            "is_selected_event",
            "memos",
        ]
