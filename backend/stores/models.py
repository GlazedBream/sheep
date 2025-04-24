from django.db import models


class Theme(models.Model):
    theme_name = models.CharField(max_length=50)
    thumbnail_url = models.CharField(max_length=255, null=True, blank=True)
    description = models.TextField(null=True, blank=True)
    is_free = models.BooleanField(default=True)
    is_default = models.BooleanField(default=False)

    def __str__(self):
        return self.theme_name


class UserTheme(models.Model):
    user = models.ForeignKey(
        "users.User", on_delete=models.CASCADE
    )  # Assuming User model is in the 'users' app
    theme = models.ForeignKey(Theme, on_delete=models.CASCADE)
    is_applied = models.BooleanField(default=False)

    class Meta:
        unique_together = ("user", "theme")  # Ensures only one theme per user

    def __str__(self):
        return f"{self.user.name} - {self.theme.theme_name}"


class StoreItem(models.Model):
    ITEM_TYPES = [
        ("paper", "Paper"),
        ("sticker", "Sticker"),
    ]

    item_name = models.CharField(max_length=50)
    description = models.TextField()
    writer = models.CharField(max_length=50, null=True, blank=True)
    price = models.IntegerField(default=0)
    content = models.TextField()
    item_type = models.CharField(max_length=7, choices=ITEM_TYPES)

    def __str__(self):
        return self.item_name


class PurchaseHistory(models.Model):
    ITEM_TYPES = [
        ("theme", "Theme"),
        ("sticker", "Sticker"),
        ("paper", "Paper"),
    ]

    user = models.ForeignKey(
        "users.User", on_delete=models.CASCADE
    )  # Assuming User model is in 'users' app
    item = models.ForeignKey(StoreItem, on_delete=models.CASCADE)
    item_type = models.CharField(max_length=20, choices=ITEM_TYPES)
    amount = models.IntegerField(default=1)
    purchased_at = models.DateTimeField()

    def __str__(self):
        return (
            f"{self.user.name} purchased {self.item.item_name} on {self.purchased_at}"
        )
