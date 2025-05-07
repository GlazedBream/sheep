from rest_framework import serializers
from .models import Diary, Emotion, DiaryKeyword
from events.models import Keyword
import os


# class DiarySerializer(serializers.ModelSerializer):
#     keywords = serializers.ListField(
#         child=serializers.CharField(),
#         write_only=True,
#         required=False,
#         help_text="키워드 텍스트 리스트"
#     )
#     emotion_id = serializers.IntegerField(
#         write_only=True,
#         required=False,
#         help_text="Emotion ID"
#     )

#     if os.getenv('USE_GEOLOCATION_BYPASS', 'False').lower() == 'true':
#         longitude = serializers.FloatField(required=False, allow_null=True)
#         latitude = serializers.FloatField(required=False, allow_null=True)
#     else:
#         galleries_location = serializers.JSONField(required=False, allow_null=True)

#     class Meta:
#         model = Diary
#         if os.getenv('USE_GEOLOCATION_BYPASS', 'False').lower() == 'true':
#             fields = [
#                 "diary_id",
#                 "user",
#                 "diary_date",
#                 "final_text",
#                 "emotion",
#                 "keywords",
#                 "emotion_id",
#                 "created_at",
#                 "updated_at",
#                 "longitude",
#                 "latitude"
#             ]
#         else:
#             fields = [
#                 "diary_id",
#                 "user",
#                 "diary_date",
#                 "final_text",
#                 "emotion",
#                 "keywords",
#                 "emotion_id",
#                 "created_at",
#                 "updated_at",
#                 "galleries_location"
#             ]
#         read_only_fields = ["user", "emotion", "created_at", "updated_at"]

#     def to_representation(self, instance):
#         data = super().to_representation(instance)
#         if os.getenv('USE_GEOLOCATION_BYPASS', 'False').lower() == 'true':
#             if hasattr(instance, 'longitude') and hasattr(instance, 'latitude'):
#                 data['longitude'] = instance.longitude
#                 data['latitude'] = instance.latitude
#             else:
#                 data['longitude'] = None
#                 data['latitude'] = None
#             data.pop('galleries_location', None)
#         else:
#             if hasattr(instance, 'galleries_location'):
#                 data['longitude'] = instance.galleries_location.get('longitude')
#                 data['latitude'] = instance.galleries_location.get('latitude')
#             else:
#                 data['longitude'] = None
#                 data['latitude'] = None
#         return data

#     def to_internal_value(self, data):
#         if os.getenv('USE_GEOLOCATION_BYPASS', 'False').lower() == 'true':
#             # longitude, latitude 필드가 있는 경우
#             longitude = data.get('longitude')
#             latitude = data.get('latitude')
#             if longitude is not None and latitude is not None:
#                 data['longitude'] = longitude
#                 data['latitude'] = latitude
#         else:
#             # galleries_location 필드가 있는 경우
#             galleries_location = data.get('galleries_location')
#             if galleries_location:
#                 data['galleries_location'] = galleries_location

#         return super().to_internal_value(data)

#     def validate_keywords(self, value):
#         """
#         키워드 텍스트를 받아서 키워드 ID 리스트로 변환
#         """
#         keyword_ids = []
#         for keyword_text in value:
#             keyword, created = Keyword.objects.get_or_create(content=keyword_text)
#             keyword_ids.append(keyword.id)
#         return keyword_ids

#     def create(self, validated_data):
#         # emotion_id에서 Emotion 객체 가져오기
#         emotion = None
#         if 'emotion_id' in validated_data:
#             emotion = Emotion.objects.get(id=validated_data['emotion_id'])

#         # Diary 객체 생성
#         diary = Diary.objects.create(
#             user=self.context['request'].user,
#             diary_date=validated_data['diary_date'],
#             final_text=validated_data['final_text'],
#             emotion=emotion
#         )

#         # 위치 정보 처리
#         if os.getenv('USE_GEOLOCATION_BYPASS', 'False').lower() == 'true':
#             # longitude, latitude 필드가 있는 경우
#             if 'longitude' in validated_data:
#                 diary.longitude = validated_data['longitude']
#             if 'latitude' in validated_data:
#                 diary.latitude = validated_data['latitude']
#         else:
#             # galleries_location 필드가 있는 경우
#             if 'galleries_location' in validated_data:
#                 diary.galleries_location = validated_data['galleries_location']

#         diary.save()

#         # 키워드 처리
#         keyword_ids = validated_data.get('keywords', [])
#         for keyword_id in keyword_ids:
#             try:
#                 keyword = Keyword.objects.get(id=keyword_id)
#                 DiaryKeyword.objects.create(
#                     diary=diary,
#                     keyword=keyword,
#                     is_selected=True,
#                     is_auto_generated=False
#                 )
#             except Keyword.DoesNotExist:
#                 continue

#         return diary

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
        required=False,
        write_only=True
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
                "latitude",
                "timeline_sent",
                "markers",
                "camera_target"
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
                "galleries_location",
                "timeline_sent",
                "markers",
                "camera_target"
            ]
        read_only_fields = ["user", "emotion", "created_at", "updated_at"]

    def to_representation(self, instance):
        data = super().to_representation(instance)
        
        # 추가된 필드들을 response에 포함
        if hasattr(instance, 'timeline_sent'):
            data['timeline_sent'] = instance.timeline_sent
        if hasattr(instance, 'markers'):
            data['markers'] = instance.markers
        if hasattr(instance, 'camera_target'):
            data['camera_target'] = instance.camera_target

        return data

    def to_internal_value(self, data):
        if 'timeline_sent' in data:
            # 'timeline' 처리
            data['timeline'] = [
                {'lat': point['lat'], 'lng': point['lng']} for point in data['timeline_sent']
            ]
        if 'markers' in data:
        # 'markers' 처리
            data['markers'] = [
            {'id': marker['id'], 'lat': marker['lat'], 'lng': marker['lng']} for marker in data['markers']
            ]
            
        if 'camera_target' in data:
            # 'camera_target' 처리
            data['camera_target'] = {
                'lat': data['camera_target']['lat'],
                'lng': data['camera_target']['lng']
            }

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

        # 위치 정보 처리
        if os.getenv('USE_GEOLOCATION_BYPASS', 'False').lower() == 'true':
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
                DiaryKeyword.objects.create(
                    diary=diary,
                    keyword=keyword,
                    is_selected=True,
                    is_auto_generated=False
                )
            except Keyword.DoesNotExist:
                continue

        return diary