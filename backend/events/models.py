from django.db import models
from users.models import User
from django.utils import timezone
# from galleries.models import Location, Picture
import os

class Timeline(models.Model):
    timeline_id = models.AutoField(primary_key=True)
    date = models.DateField()
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    events = models.ManyToManyField('Event', related_name='timelines')
    event_ids_series = models.TextField(blank=True, null=True)  # 이벤트 일련 번호를 저장하는 필드 (JSON, CSV 형식 등)

    class Meta:
        unique_together = ("date", "user")

    def __str__(self):
        return f"Timeline {self.timeline_id} ({self.date})"
    
class Event(models.Model):
    event_id = models.AutoField(primary_key=True)
    date = models.CharField(max_length=50, null=True, blank=True)  # 2005-01-01
    title = models.CharField(max_length=200, null=True, blank=True)
    time = models.CharField(max_length=50, null=True, blank=True)
    
    if os.getenv("USE_GEOLOCATION_BYPASS", "False").lower() == "true":
        longitude = models.FloatField(null=True, blank=True)
        latitude = models.FloatField(null=True, blank=True)
    else:
        location_id = models.ForeignKey('galleries.Location', on_delete=models.CASCADE)
    
    # image = models.JSONField(default=list)
    keywords = models.ManyToManyField('Keyword', related_name='events')
    memos = models.ManyToManyField('Memo', related_name='events')
    
    event_emotion_id = models.IntegerField(default=1)
    weather = models.CharField(max_length=50, default="sunny")

    def __str__(self):
        return f"Event {self.event_id} - {self.title}"
    
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
    
class Memo(models.Model):
    memo_id = models.AutoField(primary_key=True)
    event = models.ForeignKey(
        Event, 
        related_name="memo_set",  # related_name 변경
        on_delete=models.CASCADE
    )
    memo_content = models.TextField()
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Memo for Event {self.event.event_id}"

