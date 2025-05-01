from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Event
from .serializers import EventSerializer
from datetime import datetime
from drf_spectacular.utils import (
    extend_schema,
    OpenApiParameter,
    OpenApiTypes,
    OpenApiExample,
)


class EventCreateView(APIView):
    permission_classes = [IsAuthenticated]
    serializer_class = EventSerializer
    """
    API-E006: 이벤트 생성
    POST /api/events/

    201 Created: 이벤트가 성공적으로 생성됨
    400 Bad Request: 요청 데이터가 유효하지 않음
    401 Unauthorized: 인증되지 않은 사용자

    필수 요청 필드:
    - start_time: 이벤트 시작 시간 (ISO 8601 형식)

    선택적 요청 필드:
    - diary_id: 관련 일기 ID (없으면 null)
    - title: 이벤트 제목 (없으면 null)
    - longitude: 경도 (없으면 null)
    - latitude: 위도 (없으면 null)
    - event_emotion_id: 이벤트 감정 상태 ID (기본값: 1)
    - weather: 날씨 (기본값: "sunny")
    - is_selected_event: 선택된 이벤트 여부 (기본값: false)
    - memos: 이벤트 메모 배열 (기본값: 빈 배열)
    - keywords: 이벤트 키워드 배열 (기본값: 빈 배열)
        - content: 키워드 내용 (필수)
        - source_type: 키워드 출처 (선택, 기본값: "from_user")
    """

    @extend_schema(
        request=EventSerializer,
        responses={
            201: OpenApiTypes.OBJECT,
            400: OpenApiTypes.OBJECT,
            401: OpenApiTypes.OBJECT,
        },
        examples=[
            OpenApiExample(
                name="Success Example",
                value={
                    "start_time": "2025-05-01T10:00:00+09:00",
                    "longitude": 127.0,
                    "latitude": 37.0,
                    "title": "공원 산책",
                    "event_emotion_id": 1,
                    "weather": "sunny",
                    "is_selected_event": True,
                    "keywords": [
                        {
                            "content": "산책",
                            "source_type": "from_user"
                        },
                        {
                            "content": "공원",
                            "source_type": "from_user"
                        }
                    ]
                },
            ),
            OpenApiExample(
                name="Error Example",
                value={
                    "start_time": ["이 필드는 필수입니다."],
                },
            ),
        ],
    )
    def post(self, request):
        # 현재 로그인된 유저의 ID를 가져옴
        user_id = request.user.id

        # 시리얼라이저에 데이터 전달
        serializer = EventSerializer(data=request.data, context={"request": request})

        if serializer.is_valid():
            # Event 생성
            event = serializer.save(
                user_id=user_id,
                event_emotion=serializer.validated_data.get("event_emotion", "happy"),
                weather=serializer.validated_data.get("weather", "sunny"),
                is_selected_event=serializer.validated_data.get("is_selected_event", False),
            )

            # Memo 처리
            memos_data = serializer.validated_data.get("memos", [])
            for memo_data in memos_data:
                Memo.objects.create(event=event, **memo_data)

            return Response(serializer.data, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class EventUpdateView(APIView):
    permission_classes = [IsAuthenticated]
    serializer_class = EventSerializer
    """
    Event의 상세 정보를 조회(GET)하거나, 수정(PUT)하는 뷰.
    """

    """
    API-E002: 이벤트 메모 불러오기
    GET /api/events/{event_id}/

    200 OK
    401 Unauthorized
    404 Not Found
    """

    def get(self, request, event_id):
        try:
            # Event를 event_id로 조회
            event = Event.objects.get(event_id=event_id)
        except Event.DoesNotExist:
            return Response(
                {"message": "이벤트를 찾을 수 없습니다."},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Event의 상세 정보 반환
        serializer = EventSerializer(event)
        return Response(serializer.data, status=status.HTTP_200_OK)

    """
    API-E003: 이벤트 메모 저장
    PUT /api/events/{event_id}/


    """

    def put(self, request, event_id):
        try:
            # Event를 event_id로 조회
            event = Event.objects.get(event_id=event_id)
        except Event.DoesNotExist:
            return Response(
                {"message": "이벤트를 찾을 수 없습니다."},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Event 데이터 업데이트
        serializer = EventSerializer(
            event, data=request.data, partial=True
        )  # partial=True로 부분 업데이트 가능
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class EventTimelineView(APIView):
    """
    API-E001: 타임라인 불러오기
    GET /api/events/timeline/


    """

    permission_classes = [IsAuthenticated]
    serializer_class = EventSerializer

    @extend_schema(
        description="타임라인 불러오기",
        parameters=[
            OpenApiParameter(
                name="date",
                description="조회할 날짜 (YYYY-MM-DD 형식)",
                required=True,
                type=OpenApiTypes.DATE,
                location="query",
                examples=[OpenApiExample(name="date_example", value="2025-04-29")],
            )
        ],
        responses={
            200: {
                "description": "타임라인 조회 성공",
                "content": {
                    "application/json": {
                        "example": {
                            "events": [
                                {
                                    "event_id": 1,
                                    "title": "이벤트 제목",
                                    "start_time": "2025-04-29T10:00:00",
                                }
                            ]
                        }
                    }
                },
            },
            400: {
                "description": "날짜 파라미터 오류",
                "content": {
                    "application/json": {
                        "example": {"message": "'date' 파라미터가 필요합니다."}
                    }
                },
            },
        },
    )
    def get(self, request):
        # 'date' 파라미터 가져오기
        date_str = request.query_params.get("date")

        if not date_str:
            return Response(
                {"message": "'date' 파라미터가 필요합니다."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            # 날짜 파라미터를 datetime 객체로 변환
            date = datetime.strptime(date_str, "%Y-%m-%d")
        except ValueError:
            return Response(
                {
                    "message": "날짜 형식이 올바르지 않습니다. YYYY-MM-DD를 사용해주세요."
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        # 이벤트를 날짜 필터로 조회
        start_of_day = date.replace(hour=0, minute=0, second=0, microsecond=0)
        end_of_day = date.replace(hour=23, minute=59, second=59, microsecond=999999)

        # 해당 날짜에 발생한 이벤트들 조회
        events = Event.objects.filter(
            start_time__gte=start_of_day, start_time__lte=end_of_day
        )

        if not events:
            return Response(
                {"message": "해당 날짜에 이벤트가 없습니다."},
                status=status.HTTP_404_NOT_FOUND,
            )

        # 직렬화하여 반환
        serializer = EventSerializer(events, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
