from django.db import models

# from events.models import Event, Keyword


class Picture(models.Model):
    picture_id = models.AutoField(primary_key=True)
    picture_content_url = models.CharField(max_length=255)

    def __str__(self):
        return f"Picture {self.picture_id}"


class Location(models.Model):
    location_id = models.AutoField(primary_key=True)
    region_name = models.CharField(max_length=50)
    specific_name = models.CharField(max_length=100)
    longitude = models.DecimalField(max_digits=10, decimal_places=6)
    latitude = models.DecimalField(max_digits=10, decimal_places=6)

    def __str__(self):
        return f"{self.region_name} - {self.specific_name}"


class PictureKeyword(models.Model):
    keyword = models.ForeignKey("events.Keyword", on_delete=models.CASCADE)
    picture = models.ForeignKey(Picture, on_delete=models.CASCADE)
    LINK_TYPE_CHOICES = [
        ("from_picture", "From Picture"),
        ("from_keyword", "From Keyword"),
    ]
    link_type = models.CharField(max_length=20, choices=LINK_TYPE_CHOICES)

    class Meta:
        unique_together = ("picture", "keyword")

    def __str__(self):
        return (
            f"Keyword {self.keyword_id} - Picture {self.picture_id} ({self.link_type})"
        )
