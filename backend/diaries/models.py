from django.db import models
from django.conf import settings
from django.utils import timezone

# from events.models import Keyword


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


class DiaryKeyword(models.Model):
    diary = models.ForeignKey("Diary", on_delete=models.CASCADE)
    keyword = models.ForeignKey("events.Keyword", on_delete=models.CASCADE)
    is_selected = models.BooleanField()
    is_auto_generated = models.BooleanField()

    class Meta:
        unique_together = ("diary", "keyword")

    def __str__(self):
        return f"Keyword {self.keyword.content} for Diary {self.diary.id}"
