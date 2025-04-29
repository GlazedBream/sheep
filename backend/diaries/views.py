from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Diary
from .serializers import DiarySerializer
from datetime import datetime, timedelta
from drf_spectacular.utils import (
    extend_schema,
    OpenApiParameter,
    OpenApiTypes,
    OpenApiExample,
)


class DiaryCreateView(APIView):
    """
    API-D001: 일기 작성 요청
    POST /api/diaries/
    """

    permission_classes = [IsAuthenticated]
    serializer_class = DiarySerializer

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

        return Response({"diaries": diary_list}, status=status.HTTP_200_OK)


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

    def get(self, request, diary_id):
        try:
            diary = Diary.objects.get(id=diary_id)
        except Diary.DoesNotExist:
            return Response(
                {"message": "'diary_id'에 맞는 일기가 없습니다."},
                status=status.HTTP_404_NOT_FOUND,
            )

        serializer = DiarySerializer(diary)
        return Response(serializer.data, status=status.HTTP_200_OK)

    """
    API-D005: 일기 저장
    PUT /api/diaries/{diary_id}/
    """

    def put(self, request, diary_id):
        try:
            diary = Diary.objects.get(id=diary_id)
        except Diary.DoesNotExist:
            return Response(
                {"message": "'diary_id'에 맞는 일기가 없습니다."},
                status=status.HTTP_404_NOT_FOUND,
            )

        content = request.data.get("content", None)

        if content is None:
            return Response(
                {"message": "'content' 필드를 작성해주세요"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        diary.content = content
        diary.save()

        return Response(
            {"message": "일기가 수정되었습니다."},
            status=status.HTTP_200_OK,
        )
