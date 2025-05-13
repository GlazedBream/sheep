from rest_framework import generics, status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Event, Timeline
from .serializers import EventSerializer, TimelineSerializer
from datetime import datetime
from drf_spectacular.utils import (
    extend_schema,
    OpenApiParameter,
    OpenApiTypes,
    OpenApiExample,
    OpenApiResponse,
)


class TimelineCreateView(APIView):
    permission_classes = [IsAuthenticated]
    serializer_class = TimelineSerializer
    """
    API-E006: 타임라인 생성
    POST /api/events/timeline/

    201 Created: 타임라인이 성공적으로 생성됨
    400 Bad Request: 요청 데이터가 유효하지 않음
    401 Unauthorized: 인증되지 않은 사용자

    요청 필드:
    - date: 다이어리 날짜 (필수, YYYY-MM-DD 형식)
    - events: 이벤트 배열 (필수)
        - time: 이벤트 시작 시간 (필수, ISO 8601 형식)
        - longitude: 경도 (선택, 없으면 null)
        - latitude: 위도 (선택, 없으면 null)
        - title: 이벤트 제목 (선택, 없으면 null)
        - event_emotion_id: 이벤트 감정 상태 ID (선택, 기본값: 1)
        - weather: 날씨 (선택, 기본값: "sunny")
        - is_selected_event: 선택된 이벤트 여부 (선택, 기본값: false)
        - memos: 이벤트 메모 배열 (선택, 기본값: 빈 배열)
        - keywords: 이벤트 키워드 배열 (선택, 기본값: 빈 배열)
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
        parameters=[
            OpenApiParameter(
                name="date",
                type=OpenApiTypes.DATE,
                location=OpenApiParameter.QUERY,
                description="다이어리 날짜 (필수, YYYY-MM-DD 형식)",
                required=True,
            ),
            OpenApiParameter(
                name="events",
                type=OpenApiTypes.OBJECT,
                location=OpenApiParameter.QUERY,
                description="이벤트 배열 (필수)",
                required=True,
            ),
            OpenApiParameter(
                name="time",
                type=OpenApiTypes.DATETIME,
                location=OpenApiParameter.QUERY,
                description="이벤트 시작 시간 (필수, ISO 8601 형식)",
                required=True,
            ),
            OpenApiParameter(
                name="longitude",
                type=OpenApiTypes.FLOAT,
                location=OpenApiParameter.QUERY,
                description="경도 (선택, 없으면 null)",
                required=False,
            ),
            OpenApiParameter(
                name="latitude",
                type=OpenApiTypes.FLOAT,
                location=OpenApiParameter.QUERY,
                description="위도 (선택, 없으면 null)",
                required=False,
            ),
            OpenApiParameter(
                name="title",
                type=OpenApiTypes.STR,
                location=OpenApiParameter.QUERY,
                description="이벤트 제목 (선택, 없으면 null)",
                required=False,
            ),
            OpenApiParameter(
                name="event_emotion_id",
                type=OpenApiTypes.INT,
                location=OpenApiParameter.QUERY,
                description="이벤트 감정 상태 ID (선택, 기본값: 1)",
                required=False,
            ),
            OpenApiParameter(
                name="weather",
                type=OpenApiTypes.STR,
                location=OpenApiParameter.QUERY,
                description="날씨 (선택, 기본값: 'sunny')",
                required=False,
            ),
            # OpenApiParameter(
            #     name="is_selected_event",
            #     type=OpenApiTypes.BOOL,
            #     location=OpenApiParameter.QUERY,
            #     description="선택된 이벤트 여부 (선택, 기본값: false)",
            #     required=False,
            # ),
            OpenApiParameter(
                name="memos",
                type=OpenApiTypes.OBJECT,
                location=OpenApiParameter.QUERY,
                description="이벤트 메모 배열 (선택, 기본값: 빈 배열)",
                required=False,
            ),
            OpenApiParameter(
                name="keywords",
                type=OpenApiTypes.OBJECT,
                location=OpenApiParameter.QUERY,
                description="이벤트 키워드 배열 (선택, 기본값: 빈 배열)",
                required=False,
            ),
            OpenApiParameter(
                name="content",
                type=OpenApiTypes.STR,
                location=OpenApiParameter.QUERY,
                description="키워드 내용 (필수)",
                required=True,
            ),
            OpenApiParameter(
                name="source_type",
                type=OpenApiTypes.STR,
                location=OpenApiParameter.QUERY,
                description="키워드 출처 (선택, 기본값: 'from_user')",
                required=False,
            ),
        ],
        examples=[
            OpenApiExample(
                name="Success Example",
                value={
                    "date": "2025-05-01",
                    "events": [
                        {
                            "time": "2025-05-01T10:00:00+09:00",
                            "longitude": 127.0,
                            "latitude": 37.0,
                            "title": "공원 산책",
                            "event_emotion_id": 1,
                            "weather": "sunny",
                            # "is_selected_event": True,
                            "keywords": [
                                {"content": "산책", "source_type": "from_user"},
                                {"content": "공원", "source_type": "from_user"},
                            ],
                        }
                    ],
                },
            ),
            OpenApiExample(
                name="Error Example",
                value={
                    "date": ["이 필드는 필수입니다."],
                },
            ),
        ],
    )
    # def post(self, request):
    #     # 현재 로그인된 유저의 ID를 가져옴
    #     user = request.user

    #     # 요청 데이터에서 이벤트 배열 추출
    #     events_data = request.data.get("events", [])

    #     # Timeline 생성 또는 가져오기
    #     diary_date = request.data.get("diary_date")
    #     if not diary_date:
    #         return Response(
    #             {"diary_date": ["이 필드는 필수입니다."]},
    #             status=status.HTTP_400_BAD_REQUEST,
    #         )

    #     try:
    #         diary_date = datetime.strptime(diary_date, "%Y-%m-%d").date()
    #     except ValueError:
    #         return Response(
    #             {
    #                 "diary_date": [
    #                     "날짜 형식이 올바르지 않습니다. YYYY-MM-DD를 사용해주세요."
    #                 ]
    #             },
    #             status=status.HTTP_400_BAD_REQUEST,
    #         )

    #     timeline, created = Timeline.objects.get_or_create(
    #         diary_date=diary_date, user_id=user
    #     )

    #     # 각 이벤트 생성
    #     events = []
    #     for event_data in events_data:
    #         # 이벤트 시리얼라이저에 데이터 전달
    #         event_serializer = EventSerializer(
    #             data=event_data, context={"request": request}
    #         )

    #         if event_serializer.is_valid():
    #             # Event 생성
    #             event = event_serializer.save()
    #             events.append(event)
    #         else:
    #             return Response(
    #                 event_serializer.errors, status=status.HTTP_400_BAD_REQUEST
    #             )

    #     # 모든 이벤트 생성 완료 후 Timeline 시리얼라이저로 응답
    #     timeline_serializer = TimelineSerializer(timeline)
    #     return Response(timeline_serializer.data, status=status.HTTP_201_CREATED)

    def post(self, request):
        user = request.user
        events_data = request.data.get("events", [])
        date = request.data.get("date")

        if not date:
            return Response(
                {"date": ["이 필드는 필수입니다."]},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            date = datetime.strptime(date, "%Y-%m-%d").date()
        except ValueError:
            return Response(
                {"date": ["날짜 형식이 올바르지 않습니다. YYYY-MM-DD를 사용해주세요."]},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Timeline 객체 생성 또는 가져오기
        timeline, created = Timeline.objects.get_or_create(
            date=date, user=user
        )

        # 이벤트 생성 및 ID 수집
        events = []
        event_ids = []
        for event_data in events_data:
            event_serializer = EventSerializer(
                data=event_data, context={"request": request}
            )

            if event_serializer.is_valid():
                event = event_serializer.save()
                events.append(event)
                event_ids.append(event.id)
            else:
                return Response(
                    event_serializer.errors, status=status.HTTP_400_BAD_REQUEST
                )

        # 🆕 event_ids_series 필드 업데이트
        event_ids_series = ",".join(map(str, event_ids))
        timeline.event_ids_series = event_ids_series
        timeline.save()

        # 응답 반환
        timeline_serializer = TimelineSerializer(timeline)
        return Response(timeline_serializer.data, status=status.HTTP_201_CREATED)


class EventUpdateView(APIView):
    permission_classes = [IsAuthenticated]
    serializer_class = EventSerializer
    """
    API-E007: 이벤트 조회/수정
    GET /api/events/{event_id}/
    PUT /api/events/{event_id}/

    200 OK: 이벤트가 성공적으로 조회/수정됨
    400 Bad Request: 요청 데이터가 유효하지 않음
    401 Unauthorized: 인증되지 않은 사용자
    404 Not Found: 이벤트를 찾을 수 없음
    """

    @extend_schema(
        parameters=[
            OpenApiParameter(
                name="event_id",
                type=int,
                location=OpenApiParameter.PATH,
                description="이벤트의 ID",
                required=True,
            )
        ],
        responses={
            200: EventSerializer,
            401: OpenApiTypes.OBJECT,
            404: OpenApiTypes.OBJECT,
        },
    )
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

    @extend_schema(
        parameters=[
            OpenApiParameter(
                name="event_id",
                type=int,
                location=OpenApiParameter.PATH,
                description="이벤트의 ID",
                required=True,
            )
        ],
        request=EventSerializer,
        responses={
            200: EventSerializer,
            400: OpenApiTypes.OBJECT,
            401: OpenApiTypes.OBJECT,
            404: OpenApiTypes.OBJECT,
        },
    )
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
                                    "time": "2025-04-29T10:00:00",
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
            time__gte=start_of_day, time__lte=end_of_day
        )

        if not events:
            return Response(
                {"message": "해당 날짜에 이벤트가 없습니다."},
                status=status.HTTP_404_NOT_FOUND,
            )

        # 직렬화하여 반환
        serializer = EventSerializer(events, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


class EventCreateView(generics.CreateAPIView):
    queryset = Event.objects.all()
    serializer_class = EventSerializer
    permission_classes = [IsAuthenticated]

    @extend_schema(
        request=EventSerializer,
        responses={
            201: EventSerializer,
            400: OpenApiResponse(
                description="Invalid input",
                examples=[
                    OpenApiExample(
                        "Invalid date format",
                        value={
                            "detail": "Date must be in YYYY-MM-DD format"
                        }
                    ),
                    OpenApiExample(
                        "Missing required fields",
                        value={
                            "detail": "Missing required fields: date, time"
                        }
                    )
                ]
            ),
            401: OpenApiResponse(
                description="Unauthorized",
                examples=[
                    OpenApiExample(
                        "Unauthorized",
                        value={
                            "detail": "Authentication credentials were not provided."
                        }
                    )
                ]
            )
        }
    )
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)

    def perform_create(self, serializer):
        # Timeline 생성 또는 가져오기
        date = serializer.validated_data.get('date')
        user = self.request.user
        timeline, _ = Timeline.objects.get_or_create(date=date, user=user)
        
        # Event 생성
        event = serializer.save()
        
        # Timeline과 Event 연결
        timeline.events.add(event)
        timeline.save()