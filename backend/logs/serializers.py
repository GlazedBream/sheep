from rest_framework import serializers
from .models import SearchLog


class SearchLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = SearchLog
        fields = ["id", "user", "search_query", "search_date"]
        read_only_fields = ["id", "user", "search_date"]
