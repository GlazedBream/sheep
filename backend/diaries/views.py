from django.shortcuts import render
from django.http import JsonResponse

from rest_framework import status, generics, permissions
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import Diary, Emotion, Event, Keyword, Memo, EventKeyword, DiaryKeyword
from .serializers import DiarySerializer, EventSerializer
from datetime import datetime, timedelta


class DiaryCreateView(APIView):
    def post(self, request, *args, **kwargs):
        # 요청에서 받은 데이터로 시리얼라이저 생성
        data = request.data.copy()  # 복사본을 만들어서 수정 가능하게 함
        data["user"] = request.user.id  # 로그인된 사용자의 ID를 'user' 필드에 추가

        # 시리얼라이저에 데이터 전달
        serializer = DiarySerializer(data=data)

        # 시리얼라이저 검증
        if serializer.is_valid():
            # 일기 객체 저장
            serializer.save()
            # 성공적으로 생성된 일기 데이터를 응답으로 반환
            return Response(serializer.data, status=status.HTTP_201_CREATED)

        # 유효하지 않으면 오류 응답 반환
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class DiaryByMonthView(APIView):
    def get(self, request, *args, **kwargs):
        # 요청에서 'month' 파라미터 가져오기
        month = request.query_params.get("month", None)

        if not month:
            return JsonResponse(
                {"detail": "month 파라미터를 입력해주세요."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # 'month' 파라미터가 유효한지 확인
        try:
            month_date = datetime.strptime(month, "%Y-%m")
        except ValueError:
            return JsonResponse(
                {"detail": "month 형식: 'YYYY-MM'."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # 해당 월의 일기를 DB에서 조회
        start_date = month_date.replace(day=1)
        end_date = month_date.replace(
            month=month_date.month % 12 + 1, day=1
        ) - timedelta(days=1)

        diaries = Diary.objects.filter(date__gte=start_date, date__lte=end_date).values(
            "date", "diary_id", "emotion"
        )

        # 응답 데이터 구조화
        diary_list = [
            {
                "date": diary["date"].strftime("%Y-%m-%d"),
                "diary_id": diary["diary_id"],
                "emotion": diary["emotion"],
            }
            for diary in diaries
        ]

        return JsonResponse({"diaries": diary_list}, status=status.HTTP_200_OK)


class DiaryDetailView(APIView):
    """
    Diary의 세부 정보를 조회하는 뷰.
    diary_id를 통해 해당 일기의 정보를 반환.
    """

    def get(self, request, diary_id):
        try:
            # diary_id로 Diary 객체 조회
            diary = Diary.objects.get(id=diary_id)
        except Diary.DoesNotExist:
            return Response(
                {"message": "Diary not found."}, status=status.HTTP_404_NOT_FOUND
            )

        # Diary 객체를 직렬화하여 응답
        serializer = DiarySerializer(diary)
        return Response(serializer.data, status=status.HTTP_200_OK)


class EventUpdateView(APIView):
    """
    Event의 상세 정보를 조회(GET)하거나, 수정(PUT)하는 뷰.
    """

    def get(self, request, event_id):
        try:
            # Event를 event_id로 조회
            event = Event.objects.get(event_id=event_id)
        except Event.DoesNotExist:
            return Response(
                {"message": "Event not found."}, status=status.HTTP_404_NOT_FOUND
            )

        # Event의 상세 정보 반환
        serializer = EventSerializer(event)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def put(self, request, event_id):
        try:
            # Event를 event_id로 조회
            event = Event.objects.get(event_id=event_id)
        except Event.DoesNotExist:
            return Response(
                {"message": "Event not found."}, status=status.HTTP_404_NOT_FOUND
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
    주어진 날짜에 해당하는 이벤트들을 조회하는 API
    """

    def get(self, request):
        # 'date' 파라미터 가져오기
        date_str = request.query_params.get("date")

        if not date_str:
            return Response(
                {"message": "'date' parameter is required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            # 날짜 파라미터를 datetime 객체로 변환
            date = datetime.strptime(date_str, "%Y-%m-%d")
        except ValueError:
            return Response(
                {"message": "Invalid date format. Use YYYY-MM-DD."},
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
                {"message": "No events found for this date."},
                status=status.HTTP_404_NOT_FOUND,
            )

        # 직렬화하여 반환
        serializer = EventSerializer(events, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
