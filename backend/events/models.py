from django.db import models
from users.models import User
from galleries.models import Location


class Event(models.Model):
    event_id = models.AutoField(primary_key=True)
    diary_id = models.ForeignKey("diaries.Diary", on_delete=models.CASCADE)
    user_id = models.ForeignKey(User, on_delete=models.CASCADE)
    location_id = models.ForeignKey(Location, on_delete=models.CASCADE)
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
    FROM_USER = "from_user"

    SOURCE_TYPE_CHOICES = [
        (USER_INPUT, "User Input"),
        (FROM_PICTURE, "From Picture"),
        (FROM_USER, "From User"),
    ]

    content = models.CharField(max_length=50)
    source_type = models.CharField(
        max_length=20, choices=SOURCE_TYPE_CHOICES, default=FROM_USER
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
