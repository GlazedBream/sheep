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
        - memos: 이벤트 메모 배열 (선택, 기본값: 빈 배열)
        - keywords: 이벤트 키워드 배열 (선택, 기본값: 빈 배열)
            - content: 키워드 내용 (필수)
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
                                {"content": "산책"},
                                {"content": "공원"},
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
    
    def post(self, request):
        user = request.user
        print("📥 [DEBUG] 전체 request.data 수신 내용:", request.data)

        date = request.data.get("date")
        event_ids_series_raw = request.data.get("event_ids_series")

        # 날짜 검증
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

        # event_ids_series 검증
        if not isinstance(event_ids_series_raw, list):
            return Response(
                {"event_ids_series": ["이 필드는 리스트 형식이어야 합니다."]},
                status=status.HTTP_400_BAD_REQUEST,
            )

        print(f"🧩 [DEBUG] 받은 event_ids_series 리스트: {event_ids_series_raw}")

        # 🧹 -1 값 제거
        filtered_event_ids = [eid for eid in event_ids_series_raw if eid != -1]
        print(f"🧩 [DEBUG] 필터링된 이벤트 ID 리스트 (-1 제거됨): {filtered_event_ids}")

        # 🧩 문자열로 변환
        event_ids_series_str = ",".join(map(str, filtered_event_ids))
        print(f"🧩 [DEBUG] 변환된 event_ids_series 문자열: {event_ids_series_str}")

        # Timeline 객체 생성 또는 업데이트
        timeline, created = Timeline.objects.get_or_create(
            date=date, user=user
        )
        timeline.event_ids_series = event_ids_series_str
        timeline.save()

        # 응답 반환
        timeline_serializer = TimelineSerializer(timeline)
        return Response(timeline_serializer.data, status=status.HTTP_201_CREATED)

class TimelineDetailView(generics.GenericAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = TimelineSerializer

    def get(self, request, date_str):
        user = request.user
        print(f"📆 [DEBUG] 요청된 날짜: {date_str}")

        try:
            date = datetime.strptime(date_str, "%Y-%m-%d").date()
        except ValueError:
            return Response({"error": "날짜 형식이 올바르지 않습니다."}, status=400)

        try:
            timeline = Timeline.objects.get(user=user, date=date)
        except Timeline.DoesNotExist:
            return Response({"error": "해당 날짜의 타임라인이 없습니다."}, status=404)

        # 🔄 event_ids_series → 리스트
        event_ids = [int(eid) for eid in timeline.event_ids_series.split(",") if eid]

        # 📦 Event 정보 조회
        events = Event.objects.filter(id__in=event_ids)
        event_data = EventSerializer(events, many=True).data

        return Response({
            "date": date_str,
            "events": event_data,
            "timeline": TimelineSerializer(timeline).data
        })

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
    def get_object(self, event_id):
        try:
            return Event.objects.get(event_id=event_id)
        except Event.DoesNotExist:
            raise Http404

    def get(self, request, event_id):
        try:
            event = self.get_object(event_id)
            serializer = self.serializer_class(event)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Http404:
            return Response(
                {"message": "이벤트를 찾을 수 없습니다."},
                status=status.HTTP_404_NOT_FOUND
            )

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

    @extend_schema(
        request=EventSerializer,
        responses={
            200: EventSerializer,
            400: OpenApiTypes.OBJECT,
            401: OpenApiTypes.OBJECT,
            403: OpenApiTypes.OBJECT,
            404: OpenApiTypes.OBJECT,
        },
        description="이벤트를 수정합니다."
    )
    def put(self, request, event_id):
        event = self.get_object(event_id)
        
        # 요청 사용자와 이벤트 소유자가 같은지 확인
        if event.user != request.user:
            return Response(
                {"error": "이 이벤트를 수정할 권한이 없습니다."},
                status=status.HTTP_403_FORBIDDEN
            )
            
        # memos_data는 더 이상 사용하지 않음 (memo_content로 대체)
        request.data.pop('memos', None)
        keywords_data = request.data.pop('keywords', [])
        
        # 이벤트 업데이트
        serializer = self.serializer_class(event, data=request.data, partial=True)
        if serializer.is_valid():
            # 이벤트 기본 정보 업데이트 (memo_content 포함)
            updated_event = serializer.save()
            
            # 키워드 업데이트 (기존 키워드 삭제 후 새로 생성)
            event.keywords.all().delete()
            for keyword_data in keywords_data:
                Keyword.objects.create(event=event, **keyword_data)
            
            # 업데이트된 이벤트 반환
            updated_serializer = self.serializer_class(updated_event)
            return Response(updated_serializer.data)
            
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
        print(request.data.get("memo_content"))
        serializer = self.get_serializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)

    def perform_create(self, serializer):
        # Timeline 생성 또는 가져오기
        date = serializer.validated_data.get('date')
        user = self.request.user
        timeline, _ = Timeline.objects.get_or_create(date=date, user=user)
        
        # Event 생성 (시리얼라이저에서 memo_content 처리)
        event = serializer.save()

        # event_ids_series가 있으면, 해당 이벤트들을 타임라인에 연결
        event_ids_series = self.request.data.get("event_ids_series", [])
        if event_ids_series:
            # event_ids_series가 JSON 형식일 경우
            try:
                event_ids = json.loads(event_ids_series)
                valid_event_ids = [eid for eid in event_ids if eid > 0]  # 유효한 event_id 필터링
                events = Event.objects.filter(event_id__in=valid_event_ids)
                timeline.events.add(*events)  # 여러 이벤트를 타임라인에 추가
            except json.JSONDecodeError:
                pass  # 잘못된 형식의 event_ids_series 처리

        # Timeline과 Event 연결
        timeline.events.add(event)
        timeline.save()