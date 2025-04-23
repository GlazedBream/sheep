from rest_framework import generics
from rest_framework.response import Response
from datetime import datetime
from .models import Event
from .serializers import EventSerializer


class EventListByDateRangeAPIView(generics.ListAPIView):
    serializer_class = EventSerializer

    def get_queryset(self):
        start_date = self.request.query_params.get("start_date")
        end_date = self.request.query_params.get("end_date")

        if start_date and end_date:
            try:
                start_date = datetime.fromisoformat(start_date)
                end_date = datetime.fromisoformat(end_date)
            except ValueError:
                return Response({"error": "Invalid date format"}, status=400)

            return Event.objects.filter(
                timestamp_st__gte=start_date, timestamp_end__lte=end_date
            )
        return Event.objects.none()
