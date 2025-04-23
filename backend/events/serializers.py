# serializers.py

from rest_framework import serializers
from .models import Event, Location


class LocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Location
        fields = ["id", "name", "latitude", "longitude"]


class EventSerializer(serializers.ModelSerializer):
    location = LocationSerializer()

    class Meta:
        model = Event
        fields = [
            "event_id",
            "timestamp_st",
            "timestamp_end",
            "event_emotion",
            "weather",
            "is_selected_event",
            "location",
        ]
