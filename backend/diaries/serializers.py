from rest_framework import serializers
from .models import Diary, Emotion
from django.apps import apps

Keyword = apps.get_model("events", "Keyword")
import os


class DiarySerializer(serializers.ModelSerializer):
    keywords = serializers.ListField(
        child=serializers.CharField(),
        write_only=True,
        required=False,
        help_text="키워드 텍스트 리스트"
    )
    emotion_id = serializers.IntegerField(
        write_only=True,
        required=False,
        help_text="Emotion ID"
    )

    # timeline, markers, cameraTarget 추가
    timeline_sent = serializers.ListField(
        child=serializers.DictField(child=serializers.FloatField()),  # lat, lng의 형태로 처리
        required=False,
        write_only=True
    )
    markers = serializers.ListField(
        child=serializers.DictField(child=serializers.CharField()),  # marker의 id, lat, lng 등의 정보를 처리
        required=False,
        write_only=True
    )
    camera_target = serializers.DictField(
        child=serializers.FloatField(),
    )

    class Meta:
        model = Diary
        fields = [
            "diary_id",
            "user",
            "diary_date",
            "final_text",
            "emotion_id",
            "keywords",
            "created_at",
            "updated_at",
            "timeline_sent",
            "markers",
            "camera_target"
        ]
        read_only_fields = ["user", "created_at", "updated_at"]


class DiarySuggestionRequestSerializer(serializers.Serializer):
    date = serializers.CharField(
        required=True,
        help_text="일기 생성 날짜 (yyyy-MM-dd 형식)"
    )
    event_ids_series = serializers.ListField(
        child=serializers.IntegerField(),
        help_text="이벤트 ID 시리즈"
    )

    def get_keywords(self, obj):
        return [
            {
                'content': keyword.content,
                'is_selected': keyword.diarykeyword_set.first().is_selected,
                'is_auto_generated': keyword.diarykeyword_set.first().is_auto_generated
            }
            for keyword in obj.keywords.all()
        ]

    def create(self, validated_data):
        """
        일기 생성

        :param validated_data: 검증된 데이터
        :return: 생성된 Diary 객체
        """
        # emotion_id가 있으면 Emotion 객체를 가져옵니다.
        emotion_id = validated_data.pop('emotion_id', None)
        
        # Diary 객체 생성
        diary = Diary.objects.create(
            emotion_id=emotion_id,
            **validated_data
        )

        # longitude, latitude 필드가 있는 경우
        if 'longitude' in validated_data:
            diary.longitude = validated_data['longitude']
        if 'latitude' in validated_data:
            diary.latitude = validated_data['latitude']
        else:
            # galleries_location 필드가 있는 경우
            if 'galleries_location' in validated_data:
                diary.galleries_location = validated_data['galleries_location']

        # timeline, markers, camera_target 처리
        if 'timeline_sent' in validated_data:
            diary.timeline_sent = validated_data['timeline_sent']  # 예시, 실제 모델에 맞게 처리 필요
        if 'markers' in validated_data:
            diary.markers = validated_data['markers']  # 예시, 실제 모델에 맞게 처리 필요
        diary.camera_target = validated_data.get('camera_target', {})
        diary.save()

        # 키워드 처리
        keyword_ids = validated_data.get('keywords', [])
        for keyword_id in keyword_ids:
            try:
                keyword = Keyword.objects.get(id=keyword_id)
                diary.add_keyword(
                    keyword_content=keyword.content,
                    is_selected=True,
                    is_auto_generated=False
                )
            except Keyword.DoesNotExist:
                continue

        return diary