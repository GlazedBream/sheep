from django.db import models
from users.models import User
from django.utils import timezone
# from galleries.models import Location, Picture
import os
import json

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
    
    def add_events(self):
        """event_ids_series의 JSON 텍스트를 파싱하여 이벤트를 추가"""
        if self.event_ids_series:
            try:
                # event_ids_series를 JSON 파싱하여 리스트로 변환
                event_ids = json.loads(self.event_ids_series)
                
                # -1 값을 제외하고 유효한 event_id만 필터링
                valid_event_ids = [eid for eid in event_ids if eid > 0]

                # 해당 이벤트들을 찾고, ManyToMany 필드에 추가
                events = Event.objects.filter(event_id__in=valid_event_ids)
                self.events.set(events)  # ManyToMany 필드 연결
                self.save()  # 타임라인 저장
            except json.JSONDecodeError:
                # 잘못된 형식의 event_ids_series 처리
                pass
    
class Event(models.Model):
    event_id = models.AutoField(primary_key=True)
    date = models.CharField(max_length=50, null=True, blank=True)  # 2005-01-01
    title = models.CharField(max_length=200, null=True, blank=True)
    time = models.CharField(max_length=50, null=True, blank=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, null=True, related_name="events")
    
    if os.getenv("USE_GEOLOCATION_BYPASS", "False").lower() == "true":
        longitude = models.FloatField(null=True, blank=True)
        latitude = models.FloatField(null=True, blank=True)
    else:
        location_id = models.ForeignKey('galleries.Location', on_delete=models.CASCADE)
    
    # image = models.JSONField(default=list)
    
    event_emotion_id = models.IntegerField(default=1)
    weather = models.CharField(max_length=50, default="sunny")
    memo_content = models.TextField(null=True, blank=True)

    def __str__(self):
        return f"Event {self.event_id} - {self.title}"



class Keyword(models.Model):
    event = models.ForeignKey(Event, on_delete=models.CASCADE, related_name='keywords')
    content = models.CharField(max_length=50)
    

    def __str__(self):
        return f"{self.content}"
    
class Memo(models.Model):
    memo_id = models.AutoField(primary_key=True)
    event = models.ForeignKey(Event, on_delete=models.CASCADE, related_name='memos')
    memo_content = models.TextField()
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Memo for Event {self.event.event_id}"

