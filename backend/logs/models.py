from django.db import models
from django.conf import settings
from django.utils import timezone

from users.models import User


class SearchLog(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    search_type = models.CharField(max_length=50)
    search_query = models.TextField()
    search_date = models.DateTimeField(default=timezone.now)

    def __str__(self):
        return (
            f"{self.user.name} searched for {self.search_query} at {self.search_date}"
        )
