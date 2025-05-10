from django.db import models
from users.models import User
from galleries.models import Location, Picture
import os


class Timeline(models.Model):
    timeline_id = models.AutoField(primary_key=True)
    diary_date = models.DateField()
    user_id = models.ForeignKey(User, on_delete=models.CASCADE)
    diary_id = models.OneToOneField(
        "diaries.Diary",
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="timeline",
    )

    class Meta:
        unique_together = ("diary_date", "user_id")

    def __str__(self):
        return f"Timeline {self.timeline_id} ({self.diary_date})"


class Event(models.Model):
    event_id = models.AutoField(primary_key=True)
    timeline_id = models.ForeignKey(
        Timeline, on_delete=models.CASCADE, null=True, blank=True
    )
    pictures = models.ManyToManyField(Picture, related_name="events")
    if os.getenv("USE_GEOLOCATION_BYPASS", "False").lower() == "true":
        longitude = models.FloatField(null=True, blank=True)
        latitude = models.FloatField(null=True, blank=True)
    else:
        location_id = models.ForeignKey(Location, on_delete=models.CASCADE)
    title = models.CharField(max_length=200, null=True, blank=True)
    event_emotion_id = models.IntegerField(default=1)
    weather = models.CharField(max_length=50, default="sunny")
    is_selected_event = models.BooleanField(default=False)

    def __str__(self):
        return f"Event {self.event_id}"


class Memo(models.Model):
    memo_id = models.AutoField(primary_key=True)
    event = models.ForeignKey(Event, related_name="memos", on_delete=models.CASCADE)
    memo_content = models.TextField()
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Memo for Event {self.event.event_id}"


class Keyword(models.Model):
    USER_INPUT = "user_input"
    FROM_PICTURE = "from_picture"

    SOURCE_TYPE_CHOICES = [
        (USER_INPUT, "User Input"),
        (FROM_PICTURE, "From Picture"),
    ]

    content = models.CharField(max_length=50)
    source_type = models.CharField(
        max_length=20, choices=SOURCE_TYPE_CHOICES, default=USER_INPUT
    )

    def __str__(self):
        return f"{self.content} ({self.source_type})"


class EventKeyword(models.Model):
    event = models.ForeignKey(Event, on_delete=models.CASCADE)
    keyword = models.ForeignKey(Keyword, on_delete=models.CASCADE)
    is_selected_keyword = models.BooleanField()

    class Meta:
        unique_together = ("event", "keyword")

    def __str__(self):
        return f"Keyword {self.keyword.content} for Event {self.event.event_id}"
