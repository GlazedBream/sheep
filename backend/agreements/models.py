from django.db import models

from users.models import User


class Agreement(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    gps_agreement = models.BooleanField(default=False)
    personal_info = models.BooleanField(default=False)
    terms = models.BooleanField(default=False)
