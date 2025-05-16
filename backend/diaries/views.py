from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from .models import Diary, Emotion, DiaryKeyword
from .serializers import DiarySerializer, DiarySuggestionRequestSerializer
from datetime import datetime, timedelta
from django.apps import apps

Keyword = apps.get_model("events", "Keyword")

class DiaryCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = DiarySerializer(data=request.data, context={"request": request})
        if serializer.is_valid():
            emotion = None
            if "emotion_id" in serializer.validated_data:
                emotion = Emotion.objects.get(id=serializer.validated_data["emotion_id"])
            diary = serializer.save(emotion=emotion, user=request.user)

            keywords = request.data.get('keywords', [])
            for keyword_data in keywords:
                diary.add_keyword(
                    keyword_content=keyword_data['content'],
                    is_selected=keyword_data.get('is_selected', True),
                    is_auto_generated=keyword_data.get('is_auto_generated', False)
                )

            diary.timeline_sent = request.data.get('timeline_sent', [])
            diary.markers = request.data.get('markers', [])
            diary.camera_target = request.data.get('camera_target', [])
            diary.save()

            return Response({"message": "일기가 성공적으로 작성되었습니다."}, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class DiaryByMonthView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        month = request.query_params.get("month", None)
        if not month:
            return Response({"detail": "month 파라미터를 입력해주세요."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            month_date = datetime.strptime(month, "%Y-%m")
        except ValueError:
            return Response({"detail": "month 형식: 'YYYY-MM'."}, status=status.HTTP_400_BAD_REQUEST)

        start_date = month_date.replace(day=1)
        end_date = (start_date.replace(day=28) + timedelta(days=4)).replace(day=1) - timedelta(days=1)

        diaries = Diary.objects.filter(user=request.user, diary_date__range=(start_date, end_date)).order_by("-diary_date")

        diary_data = []
        for diary in diaries:
            keywords = [dk.keyword.content for dk in DiaryKeyword.objects.filter(diary=diary)]
            emotion = diary.emotion.emotion_label if diary.emotion else ""
            diary_data.append({
                "date": diary.diary_date.strftime("%Y-%m-%d"),
                "diary_id": diary.diary_id,
                "emotion": emotion,
                "keywords": keywords,
                "emotion_id": diary.emotion_id if diary.emotion_id else None,
            })

        return Response({"diaries": diary_data}, status=status.HTTP_200_OK)


class DiaryDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, diary_date):
        try:
            diary = Diary.objects.get(diary_date=diary_date)
        except Diary.DoesNotExist:
            return Response({"message": "'diary_date'에 맞는 일기가 없습니다."}, status=status.HTTP_404_NOT_FOUND)

        serializer = DiarySerializer(diary)
        data = serializer.data
        data['longitude'] = getattr(diary, 'longitude', None)
        data['latitude'] = getattr(diary, 'latitude', None)
        return Response(data, status=status.HTTP_200_OK)

    def put(self, request, diary_date):
        try:
            diary = Diary.objects.get(diary_date=diary_date)
        except Diary.DoesNotExist:
            return Response({"message": "'diary_date'에 맞는 일기가 없습니다."}, status=status.HTTP_404_NOT_FOUND)

        content = request.data.get("final_text", None)
        if content is None:
            return Response({"message": "'final_text' 필드를 작성해주세요"}, status=status.HTTP_400_BAD_REQUEST)

        longitude = request.data.get('longitude', None)
        latitude = request.data.get('latitude', None)
        if longitude is not None:
            diary.longitude = longitude
        if latitude is not None:
            diary.latitude = latitude

        diary.final_text = content
        diary.save()

        return Response({"message": "일기가 수정되었습니다."}, status=status.HTTP_200_OK)


class DiarySuggestionView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        print("🔥 Raw request data:", request.data)

        serializer = DiarySuggestionRequestSerializer(data=request.data)
        if not serializer.is_valid():
            print("❌ Serializer errors:", serializer.errors)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        try:
            validated_data = serializer.validated_data
            print("✅ validated_data:", validated_data)

            event_ids_list = validated_data.get('event_ids_series', [])
            print("📌 event_ids_series:", event_ids_list)

            event_ids = [eid for eid in event_ids_list if eid != -1]
            print("🧹 cleaned event_ids:", event_ids)

            Event = apps.get_model("events", "Event")
            events = Event.objects.filter(event_id__in=event_ids).order_by('time')
            print("📦 events queryset count:", events.count())

            events_data = []
            for event in events:
                event_info = {
                    'id': event.event_id,
                    'place': event.title.split("에서")[1],
                    'emotion': event.event_emotion_id,
                    'keywords': [kw.content for kw in event.keywords.all()],
                    'start_time': event.time
                }
                print("🧾 Event parsed:", event_info)
                events_data.append(event_info)

            from ai_models.diary_generator.diary_generator import process_event, generate_diary
            processed_events = [process_event(e) for e in events_data]
            diary_text = generate_diary(processed_events)
            emotion_id = event_info.get('emotion', 1)

            diary = Diary.objects.create(
                user=request.user,
                diary_date=validated_data.get('date'),
                final_text=diary_text,
                emotion_id_id=emotion_id
            )

            for keyword in processed_events[0].get('keywords', []):
                keyword_obj, created = Keyword.objects.get_or_create(content=keyword)
                DiaryKeyword.objects.create(
                    diary=diary,
                    keyword=keyword_obj,
                    is_selected=True,
                    is_auto_generated=True
                )

            diary_serializer = DiarySerializer(diary)
            return Response(diary_serializer.data, status=status.HTTP_200_OK)

        except Exception as e:
            import traceback
            traceback.print_exc()  # 콘솔에 전체 traceback 출력
            return Response({
                "message": "Internal server error",
                "error": str(e)  # 임시로 에러 메시지도 리턴
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
