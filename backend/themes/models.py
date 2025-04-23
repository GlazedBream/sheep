from django.db import models


class Theme(models.Model):
    name = models.CharField(max_length=100)
    thumbnail_url = models.URLField()
    description = models.TextField()
    is_free = models.BooleanField(default=False)
    is_default = models.BooleanField(default=False)

    def __str__(self):
        return self.name
