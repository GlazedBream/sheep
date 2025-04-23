from django.db import models


class Location(models.Model):
    location_id = models.AutoField(
        primary_key=True
    )  # AUTO_INCREMENT가 기본으로 처리됩니다.
    region_name = models.CharField(max_length=50)
    specific_name = models.CharField(max_length=100)
    longitude = models.DecimalField(max_digits=10, decimal_places=6)
    latitude = models.DecimalField(max_digits=10, decimal_places=6)

    def __str__(self):
        return f"{self.region_name} - {self.specific_name}"
