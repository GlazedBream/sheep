from rest_framework import generics, permissions
from .models import SearchLog
from .serializers import SearchLogSerializer


class SearchLogListCreateView(generics.ListCreateAPIView):
    serializer_class = SearchLogSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return SearchLog.objects.filter(user=self.request.user).order_by("-searched_at")

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
