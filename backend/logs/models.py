from django.db import models
from django.conf import settings

from users.models import User


class SearchLog(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    search_type = models.CharField(max_length=50)
    search_query = models.CharField(max_length=255)
    search_date = models.DateTimeField()

    def __str__(self):
        return f"{self.user.name} searched for {self.search_query}"
