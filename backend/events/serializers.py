from rest_framework import serializers
from .models import Event, Keyword, Memo, EventKeyword


class MemoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Memo
        fields = ["memo_content"]


class EventSerializer(serializers.ModelSerializer):
    memos = MemoSerializer(many=True)  # read_only 제거

    class Meta:
        model = Event
        fields = [
            "event_id",
            "diary_id",
            "user_id",
            "location_id",
            "start_time",
            "end_time",
            "event_emotion",
            "weather",
            "is_selected_event",
            "memos",
        ]

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
