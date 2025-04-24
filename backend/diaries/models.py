from django.db import models
from django.conf import settings
from django.utils import timezone


class Diary(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    title = models.CharField(max_length=100)
    diary_date = models.DateTimeField(default=timezone.now)
    final_text = models.TextField()
    emotion = models.ForeignKey("Emotion", on_delete=models.SET_NULL, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.title} ({self.user.email})"


class Emotion(models.Model):
    emotion_label = models.CharField(max_length=50)

    def __str__(self):
        return self.emotion_label


class Event(models.Model):
    event_id = models.AutoField(primary_key=True)
    diary_id = models.ForeignKey(Diary, on_delete=models.CASCADE)
    user_id = models.ForeignKey("users.User", on_delete=models.CASCADE)
    location_id = models.ForeignKey("galleries.Location", on_delete=models.CASCADE)
    start_time = models.DateTimeField()
    end_time = models.DateTimeField()
    event_emotion = models.CharField(max_length=50)
    weather = models.CharField(max_length=50)
    is_selected_event = models.BooleanField()

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
    source_type = models.CharField(max_length=20, choices=SOURCE_TYPE_CHOICES)

    def __str__(self):
        return f"{self.content} ({self.source_type})"


class EventKeyword(models.Model):
    event = models.ForeignKey("Event", on_delete=models.CASCADE)
    keyword = models.ForeignKey("Keyword", on_delete=models.CASCADE)
    is_selected_keyword = models.BooleanField()

    class Meta:
        unique_together = ("event", "keyword")

    def __str__(self):
        return f"Keyword {self.keyword.content} for Event {self.event.event_id}"


class DiaryKeyword(models.Model):
    diary = models.ForeignKey("Diary", on_delete=models.CASCADE)
    keyword = models.ForeignKey("Keyword", on_delete=models.CASCADE)
    is_selected = models.BooleanField()
    is_auto_generated = models.BooleanField()

    class Meta:
        unique_together = ("diary", "keyword")

    def __str__(self):
        return f"Keyword {self.keyword.content} for Diary {self.diary.id}"
