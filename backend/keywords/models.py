from django.db import models

class Event(models.Model):
    title = models.CharField(max_length=200)
    longitude = models.FloatField()
    latitude = models.FloatField()
    start_time = models.CharField(max_length=10)  # Format: "HH:MM"
    emotion = models.CharField(max_length=2)      # Emotion ID
    memos = models.TextField(blank=True)
    keywords = models.JSONField(default=list)     # Store keywords as JSON array
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title
