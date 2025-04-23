from django.shortcuts import render

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status

from django.utils import timezone

from users.models import User
from users.serializers import UserProfileSerializer


class DailyStatusView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # 현재 로그인된 사용자 정보 가져오기
        user_profile = request.user.profile

        # 오늘 날짜
        today_date = timezone.now().date()

        # 감정 및 일기 작성 여부 가져오기
        emotion = user_profile.today_emotion  # 예시 필드
        diary_exists = user_profile.today_diary.exists()  # 예시 필드

        # 응답 데이터 반환
        return Response(
            {
                "is_authenticated": True,
                "today_date": today_date,
                "emotion": emotion,
                "diary_exists": diary_exists,
            },
            status=status.HTTP_200_OK,
        )


class ProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        serializer = UserProfileSerializer(user)
        return Response(serializer.data, status=status.HTTP_200_OK)
