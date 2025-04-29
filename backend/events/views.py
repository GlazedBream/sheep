from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Event
from .serializers import EventSerializer
from datetime import datetime


class EventUpdateView(APIView):
    permission_classes = [IsAuthenticated]
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
    """
    주어진 날짜에 해당하는 이벤트들을 조회하는 API
    """

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
            start_time__gte=start_of_day, end_time__lte=end_of_day
        )

        if not events:
            return Response(
                {"message": "해당 날짜에 이벤트가 없습니다."},
                status=status.HTTP_404_NOT_FOUND,
            )

        # 직렬화하여 반환
        serializer = EventSerializer(events, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
