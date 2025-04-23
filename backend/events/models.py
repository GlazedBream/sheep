from django.db import models


class Event(models.Model):
    event_id = models.AutoField(primary_key=True)
    diary_id = models.ForeignKey("diaries.Diary", on_delete=models.CASCADE)
    user_id = models.ForeignKey("users.User", on_delete=models.CASCADE)
    location_id = models.ForeignKey("locations.Location", on_delete=models.CASCADE)
    timestamp_st = models.DateTimeField()
    timestamp_end = models.DateTimeField()
    event_emotion = models.CharField(
        max_length=20, choices=[("TBD", "To Be Determined")]
    )
    weather = models.CharField(max_length=20, choices=[("TBD", "To Be Determined")])
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
