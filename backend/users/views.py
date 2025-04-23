from django.shortcuts import render

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status

from users.models import User
from users.serializers import UserProfileSerializer


class DailyStatusView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # 임시 응답: 실제 구현은 추후 로직 추가
        return Response(
            {
                "date": "2025-04-23",
                "has_written_today": False,
                "pending_tasks": [],
            },
            status=status.HTTP_200_OK,
        )


class ProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        serializer = UserProfileSerializer(user)
        return Response(serializer.data, status=status.HTTP_200_OK)
