from rest_framework import serializers
from .models import Diary, Emotion, DiaryKeyword
from events.models import Keyword
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

    if os.getenv('USE_GEOLOCATION_BYPASS', 'False').lower() == 'true':
        longitude = serializers.FloatField(required=False, allow_null=True)
        latitude = serializers.FloatField(required=False, allow_null=True)
    else:
        galleries_location = serializers.JSONField(required=False, allow_null=True)

    class Meta:
        model = Diary
        if os.getenv('USE_GEOLOCATION_BYPASS', 'False').lower() == 'true':
            fields = [
                "diary_id",
                "user",
                "diary_date",
                "final_text",
                "emotion",
                "keywords",
                "emotion_id",
                "created_at",
                "updated_at",
                "longitude",
                "latitude"
            ]
        else:
            fields = [
                "diary_id",
                "user",
                "diary_date",
                "final_text",
                "emotion",
                "keywords",
                "emotion_id",
                "created_at",
                "updated_at",
                "galleries_location"
            ]
        read_only_fields = ["user", "emotion", "created_at", "updated_at"]

    def to_representation(self, instance):
        data = super().to_representation(instance)
        if os.getenv('USE_GEOLOCATION_BYPASS', 'False').lower() == 'true':
            if instance.galleries_location:
                data['longitude'] = instance.galleries_location.get('longitude')
                data['latitude'] = instance.galleries_location.get('latitude')
            data.pop('galleries_location', None)
        return data

    def to_internal_value(self, data):
        if os.getenv('USE_GEOLOCATION_BYPASS', 'False').lower() == 'true':
            longitude = data.get('longitude')
            latitude = data.get('latitude')
            if longitude is not None and latitude is not None:
                data['galleries_location'] = {'longitude': longitude, 'latitude': latitude}
        return super().to_internal_value(data)

    def validate_keywords(self, value):
        """
        키워드 텍스트를 받아서 키워드 ID 리스트로 변환
        """
        keyword_ids = []
        for keyword_text in value:
            keyword, created = Keyword.objects.get_or_create(content=keyword_text)
            keyword_ids.append(keyword.id)
        return keyword_ids

    def create(self, validated_data):
        # emotion_id에서 Emotion 객체 가져오기
        emotion = None
        if 'emotion_id' in validated_data:
            emotion = Emotion.objects.get(id=validated_data['emotion_id'])

        # Diary 객체 생성
        diary = Diary.objects.create(
            user=self.context['request'].user,
            diary_date=validated_data['diary_date'],
            final_text=validated_data['final_text'],
            emotion=emotion
        )

        # 키워드 처리
        keyword_ids = validated_data.get('keywords', [])
        for keyword_id in keyword_ids:
            try:
                keyword = Keyword.objects.get(id=keyword_id)
                DiaryKeyword.objects.create(
                    diary=diary,
                    keyword=keyword,
                    is_selected=True,
                    is_auto_generated=False
                )
            except Keyword.DoesNotExist:
                continue

        return diary
