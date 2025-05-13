from rest_framework import serializers
from galleries.models import Location
from diaries.models import Diary
from .models import Event, Timeline, Memo, Keyword
import os

class MemoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Memo
        fields = ["memo_content"]
        extra_kwargs = {
            'memo_content': {'required': False}  # memo_content 필드를 선택적으로 만들기
        }  # 필요에 따라 확장


class KeywordSerializer(serializers.ModelSerializer):
    class Meta:
        model = Keyword
        fields = ["content", "source_type"]


class TimelineSerializer(serializers.ModelSerializer):
    class Meta:
        model = Timeline
        fields = ['timeline_id', 'date', 'user', 'events', 'event_ids_series']


class EventSerializer(serializers.ModelSerializer):
    time = serializers.CharField()
    emotion_id = serializers.IntegerField(source="event_emotion_id")
    # images = serializers.ListField(
    #     child=serializers.ImageField(), required=False
    # )
    memos = MemoSerializer(many=True, required=False)
    keywords = KeywordSerializer(many=True, required=False)

    class Meta:
        model = Event
        fields = [
            "event_id",
            "date",
            "time",
            "longitude",
            "latitude",
            "title",
            "emotion_id",
            "weather",
            "memos",
            "keywords",
            # "images",
        ]
        extra_kwargs = {
            'date': {'required': True},
            'time': {'required': True},
            'longitude': {'required': False},
            'latitude': {'required': False},
            'title': {'required': False},
            'emotion_id': {'default': 1},
            'weather': {'default': 'sunny'},
            'memos': {'default': []},
            'keywords': {'default': []},
            # 'images': {'default': []},
        }

    def create(self, validated_data):
        memos_data = validated_data.pop('memos', [])
        keywords_data = validated_data.pop('keywords', [])
        # images_data = validated_data.pop('images', [])

        # 위도와 경도가 없을 경우 기본값 설정
        if 'longitude' not in validated_data:
            validated_data['longitude'] = None
        if 'latitude' not in validated_data:
            validated_data['latitude'] = None

        event = Event.objects.create(**validated_data)

        # Memo 생성
        for memo_data in memos_data:
            Memo.objects.create(event=event, **memo_data)

        # Keyword 생성
        for keyword_data in keywords_data:
            Keyword.objects.create(event=event, **keyword_data)

        # 이미지 저장
        # for image in images_data:
        #     event.images.append(image)
        event.save()

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

