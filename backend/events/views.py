from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Event
from .serializers import EventSerializer


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
                {"detail": "Event not found."}, status=status.HTTP_404_NOT_FOUND
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
                {"detail": "Event not found."}, status=status.HTTP_404_NOT_FOUND
            )

        # Event 데이터 업데이트
        serializer = EventSerializer(
            event, data=request.data, partial=True
        )  # partial=True로 부분 업데이트 가능
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
