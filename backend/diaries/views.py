from rest_framework import status, serializers
from rest_framework.views import APIView
from rest_framework.generics import GenericAPIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Diary, DiaryKeyword, Emotion
from events.models import Keyword
from .serializers import DiarySerializer
from datetime import datetime, timedelta
from drf_spectacular.utils import (
    extend_schema,
    OpenApiParameter,
    OpenApiTypes,
    OpenApiExample,
)
import os
from .tasks import generate_diary_task
from celery.result import AsyncResult
import uuid

class DiaryCreateView(APIView):
    """
    API-D001: 일기 작성 요청
    POST /api/diaries/
    """

    permission_classes = [IsAuthenticated]
    serializer_class = DiarySerializer

    @extend_schema(
        request=DiarySerializer,
        responses={
            201: {
                "description": "일기 작성 성공",
                "content": {
                    "application/json": {
                        "example": {"message": "일기가 성공적으로 작성되었습니다."}
                    }
                },
            },
            400: {
                "description": "유효성 검사 실패",
                "content": {
                    "application/json": {
                        "example": {
                            "keywords": ["키워드는 필수입니다."],
                            "emotion_id": ["유효한 감정 ID가 아닙니다."],
                        }
                    }
                },
            },
        },
    )
    def post(self, request, *args, **kwargs):
        # 시리얼라이저에 데이터 전달 (request context 포함)
        serializer = DiarySerializer(data=request.data, context={"request": request})

        if serializer.is_valid():
            # Emotion 객체 가져오기
            emotion = None
            if "emotion_id" in serializer.validated_data:
                emotion = Emotion.objects.get(
                    id=serializer.validated_data["emotion_id"]
                )

            # Diary 객체 생성
            diary = serializer.save(emotion=emotion)

            # 키워드 처리
            keyword_ids = serializer.validated_data.get("keywords", [])
            for keyword_id in keyword_ids:
                try:
                    keyword = Keyword.objects.get(id=keyword_id)
                    DiaryKeyword.objects.create(
                        diary=diary,
                        keyword=keyword,
                        is_selected=True,
                        is_auto_generated=False,
                    )
                except Keyword.DoesNotExist:
                    continue

            # 추가된 정보 처리 (예: 타임라인, 마커 등)
            timeline_sent = request.data.get('timeline_sent', [])
            markers = request.data.get('markers', [])
            camera_target = request.data.get('cameraTarget', {})

            # 필요한 필드 저장
            diary.timeline_sent = timeline_sent
            diary.markers = markers
            diary.camera_target = camera_target

            # 일기 저장
            diary.save()

            return Response(
                {"message": "일기가 성공적으로 작성되었습니다."},
                status=status.HTTP_201_CREATED,
            )

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class DiaryByMonthView(APIView):
    """
    API-D002: 일기 목록 불러오기(월별)
    GET /api/diaries/dates/
    """

    permission_classes = [IsAuthenticated]
    serializer_class = DiarySerializer

    @extend_schema(
        description="월별 일기 목록 조회",
        parameters=[
            OpenApiParameter(
                name="month",
                description="조회할 월 (YYYY-MM 형식)",
                required=True,
                type=OpenApiTypes.DATE,
                location="query",
                examples=[OpenApiExample(name="month_example", value="2025-04")],
            )
        ],
        responses={
            200: {
                "description": "일기 목록 조회 성공",
                "content": {
                    "application/json": {
                        "example": {
                            "diaries": [
                                {
                                    "date": "2025-04-01",
                                    "diary_id": 1,
                                    "emotion": "happy",
                                    "keywords": ["keyword1", "keyword2"],
                                    "emotion_id": 1,
                                }
                            ]
                        }
                    }
                },
            },
            400: {
                "description": "월 파라미터 오류",
                "content": {
                    "application/json": {
                        "example": {"message": "month 파라미터를 입력해주세요."}
                    }
                },
            },
        },
    )
    @extend_schema(
        parameters=[
            OpenApiParameter(
                name="month",
                description="조회할 월 (YYYY-MM 형식)",
                required=True,
                type=OpenApiTypes.DATE,
                location=OpenApiParameter.QUERY,
            )
        ],
        responses={200: OpenApiTypes.OBJECT, 400: OpenApiTypes.OBJECT},
        examples=[
            OpenApiExample(
                name="Success Example",
                value={
                    "diaries": [
                        {
                            "date": "2025-04-01",
                            "diary_id": 1,
                            "emotion": "happy",
                            "keywords": ["keyword1", "keyword2"],
                            "emotion_id": 1,
                            **(
                                {"longitude": 127.0, "latitude": 37.0}
                                if os.getenv("USE_GEOLOCATION_BYPASS", "False").lower()
                                == "true"
                                else {
                                    "galleries_location": {
                                        "type": "Point",
                                        "coordinates": [127.0, 37.0],
                                    }
                                }
                            ),
                        }
                    ]
                },
            ),
            OpenApiExample(
                name="Error Example", value={"detail": "month 파라미터를 입력해주세요."}
            ),
        ],
    )
    def get(self, request, *args, **kwargs):
        # 요청에서 'month' 파라미터 가져오기
        month = request.query_params.get("month", None)

        if not month:
            return Response(
                {"detail": "month 파라미터를 입력해주세요."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # 'month' 파라미터가 유효한지 확인
        try:
            month_date = datetime.strptime(month, "%Y-%m")
        except ValueError:
            return Response(
                {"detail": "month 형식: 'YYYY-MM'."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # 해당 월의 일기 목록 조회
        start_date = month_date.replace(day=1)
        end_date = (start_date.replace(day=28) + timedelta(days=4)).replace(
            day=1
        ) - timedelta(days=1)
        diaries = Diary.objects.filter(
            user=request.user, diary_date__range=(start_date, end_date)
        ).order_by("-diary_date")

        # 일기별로 키워드와 감정 상태 가져오기
        diary_data = []
        for diary in diaries:
            # 키워드 가져오기
            keywords = [
                diary_keyword.keyword.content
                for diary_keyword in DiaryKeyword.objects.filter(diary=diary)
            ]

            # 감정 상태 가져오기
            emotion = diary.emotion.name if diary.emotion else ""

            diary_data.append(
                {
                    "date": diary.diary_date.strftime("%Y-%m-%d"),
                    "diary_id": diary.diary_id,
                    "emotion": emotion,
                    "keywords": keywords,
                    "emotion_id": diary.emotion_id if diary.emotion_id else None,
                }
            )

        return Response({"diaries": diary_data}, status=status.HTTP_200_OK)


class DiaryDetailView(APIView):
    """
    Diary의 세부 정보를 조회하거나 수정하는 뷰.
    """

    permission_classes = [IsAuthenticated]
    serializer_class = DiarySerializer

    """
    API-D003: 일기 불러오기
    GET /api/diaries/{diary_id}/
    """

    def get(self, request, diary_date):
        try:
            diary = Diary.objects.get(diary_date=diary_date)
        except Diary.DoesNotExist:
            return Response(
                {"message": "'diary_date'에 맞는 일기가 없습니다."},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Diary 모델의 필드를 조건부로 처리
        if os.getenv('USE_GEOLOCATION_BYPASS', 'False').lower() == 'true':
            # longitude, latitude 필드가 있는 경우
            serializer = DiarySerializer(diary)
            serializer_data = serializer.data
            if hasattr(diary, 'longitude') and hasattr(diary, 'latitude'):
                serializer_data['longitude'] = diary.longitude
                serializer_data['latitude'] = diary.latitude
            else:
                serializer_data['longitude'] = None
                serializer_data['latitude'] = None
        else:
            # galleries_location 필드가 있는 경우
            serializer = DiarySerializer(diary)
            serializer_data = serializer.data
            if hasattr(diary, 'galleries_location'):
                if diary.galleries_location:
                    serializer_data['longitude'] = diary.galleries_location.get('longitude')
                    serializer_data['latitude'] = diary.galleries_location.get('latitude')
                else:
                    serializer_data['longitude'] = None
                    serializer_data['latitude'] = None
            else:
                serializer_data['longitude'] = None
                serializer_data['latitude'] = None

        return Response(serializer_data, status=status.HTTP_200_OK)

    """
    API-D005: 일기 저장
    PUT /api/diaries/{diary_id}/
    """

    def put(self, request, diary_id):
        try:
            diary = Diary.objects.get(diary_id=diary_id)
        except Diary.DoesNotExist:
            return Response(
                {"message": "'diary_id'에 맞는 일기가 없습니다."},
                status=status.HTTP_404_NOT_FOUND,
            )

        content = request.data.get("final_text", None)

        if content is None:
            return Response(
                {"message": "'final_text' 필드를 작성해주세요"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Diary 모델의 필드를 조건부로 처리
        if os.getenv('USE_GEOLOCATION_BYPASS', 'False').lower() == 'true':
            # longitude, latitude 필드가 있는 경우
            longitude = request.data.get('longitude', None)
            latitude = request.data.get('latitude', None)
            
            if longitude is not None:
                diary.longitude = longitude
            if latitude is not None:
                diary.latitude = latitude
        else:
            # galleries_location 필드가 있는 경우
            galleries_location = request.data.get('galleries_location', None)
            if galleries_location:
                diary.galleries_location = galleries_location
            else:
                diary.galleries_location = None

        diary.final_text = content
        diary.save()
        
        return Response(
            {"message": "일기가 수정되었습니다."},
            status=status.HTTP_200_OK,
        )


class DiarySuggestionRequestSerializer(serializers.Serializer):
    event_ids = serializers.ListField(
        child=serializers.IntegerField(),
        required=True,
        help_text="이벤트 ID 목록"
    )

    class Meta:
        extra_kwargs = {
            'event_ids': {
                'example': [1, 2, 3],
                'description': '일기 생성을 위한 이벤트 ID 목록'
            }
        }


class DiarySuggestionResponseSerializer(serializers.Serializer):
    task_id = serializers.CharField(help_text="작업 ID")
    status = serializers.CharField(help_text="작업 상태")

    class Meta:
        extra_kwargs = {
            'task_id': {'example': '550e8400-e29b-41d4-a716-446655440000'},
            'status': {'example': '작업이 시작되었습니다.'}
        }


class DiarySuggestionView(APIView):
    permission_classes = [IsAuthenticated]
    
    @extend_schema(
        request=DiarySuggestionRequestSerializer,
        responses={202: DiarySuggestionResponseSerializer},
        description="이벤트 ID 목록을 기반으로 일기 생성을 요청합니다."
    )
    def post(self, request):
        serializer = DiarySuggestionRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(
                serializer.errors,
                status=status.HTTP_400_BAD_REQUEST
            )
            
        user = request.user
        event_ids = serializer.validated_data['event_ids']
        
        # 비동기 작업 실행
        task = generate_diary_task.delay(user.id, event_ids)
        
        response_data = {
            'task_id': task.id,
            'status': '작업이 시작되었습니다.'
        }
        response_serializer = DiarySuggestionResponseSerializer(data=response_data)
        response_serializer.is_valid(raise_exception=True)
        
        return Response(
            response_serializer.data,
            status=status.HTTP_202_ACCEPTED
        )


class TaskStatusResponseSerializer(serializers.Serializer):
    task_id = serializers.CharField(help_text="작업 ID")
    status = serializers.CharField(help_text="작업 상태")
    result = serializers.DictField(
        required=False,
        help_text="작업 결과 (작업이 완료된 경우에만 포함)"
    )
    error = serializers.CharField(
        required=False,
        help_text="에러 메시지 (작업이 실패한 경우에만 포함)"
    )

    class Meta:
        extra_kwargs = {
            'task_id': {'example': '550e8400-e29b-41d4-a716-446655440000'},
            'status': {'example': 'SUCCESS'},
            'result': {'example': {'diary_id': 1, 'message': '일기가 생성되었습니다.'}},
            'error': {'example': '일기 생성 중 오류가 발생했습니다.'}
        }


class TaskStatusView(GenericAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = TaskStatusResponseSerializer
    
    @extend_schema(
        responses={200: TaskStatusResponseSerializer},
        parameters=[
            OpenApiParameter(
                name='task_id',
                type=OpenApiTypes.UUID,
                location=OpenApiParameter.PATH,
                description='작업 ID',
                required=True
            )
        ],
        description="작업의 현재 상태를 조회합니다."
    )
    def get(self, request, task_id):
        try:
            # Celery 작업 상태 확인
            task_result = AsyncResult(task_id)
            
            response = {
                'task_id': task_id,
                'status': task_result.status,
                'result': task_result.result if task_result.ready() else None
            }
            
            if task_result.failed():
                response['error'] = str(task_result.result)
                response_serializer = self.get_serializer(data=response)
                response_serializer.is_valid(raise_exception=True)
                return Response(
                    response_serializer.data,
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
                
            response_serializer = self.get_serializer(data=response)
            response_serializer.is_valid(raise_exception=True)
            return Response(response_serializer.data)
            
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )