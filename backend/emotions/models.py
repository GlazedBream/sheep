from django.db import models


class Emotion(models.Model):
    emotion_label = models.CharField(max_length=50)

    def __str__(self):
        return self.emotion_label
