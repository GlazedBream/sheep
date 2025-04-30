from django.db import models
from django.conf import settings
from django.utils import timezone

from events.models import Keyword


class Diary(models.Model):
    diary_id = models.AutoField(primary_key=True)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)

    diary_date = models.DateField(default=timezone.now)
    final_text = models.TextField()
    emotion = models.ForeignKey("Emotion", on_delete=models.SET_NULL, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.final_text} ({self.emotion})"


class Emotion(models.Model):
    emotion_label = models.CharField(max_length=50)

    def __str__(self):
        return self.emotion_label


class DiaryKeyword(models.Model):
    diary = models.ForeignKey("Diary", on_delete=models.CASCADE)
    keyword = models.ForeignKey(Keyword, on_delete=models.CASCADE)
    is_selected = models.BooleanField(default=True)
    is_auto_generated = models.BooleanField(default=False)

    class Meta:
        verbose_name = "일기 키워드"
        verbose_name_plural = "일기 키워드 목록"

    def __str__(self):
        return f"Keyword {self.keyword} for Diary {self.diary.id}"
