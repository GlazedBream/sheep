from django.db import models

# from events.models import Event, Keyword


class Picture(models.Model):
    class Status(models.TextChoices):
        TEMP = 'temp', '임시 저장'
        SAVED = 'saved', '저장 완료'
        
    picture_id = models.AutoField(primary_key=True)
    s3_key = models.CharField(max_length=500, help_text='S3 버킷 내의 파일 경로 (예: temp/filename.jpg 또는 saved/2023/01/filename.jpg)', null=True, blank=True)
    status = models.CharField(
        max_length=10,
        choices=Status.choices,
        default=Status.TEMP,
        help_text='이미지 상태 (임시 저장/저장 완료)'
    )
    picture_caption = models.TextField(null=True, blank=True, help_text='이미지 캡션')
    user = models.ForeignKey(
        'users.User', 
        on_delete=models.CASCADE, 
        related_name='pictures',
        null=True
    )

    @property
    def url(self):
        """S3 객체의 전체 URL을 반환합니다."""
        from django.conf import settings
        if not self.s3_key:
            return None
        return f"https://{settings.AWS_STORAGE_BUCKET_NAME}.s3.{settings.AWS_S3_REGION_NAME}.amazonaws.com/{self.s3_key}"

    def move_to_saved(self):
        """이미지를 임시 폴더에서 저장 폴더로 이동합니다."""
        if self.status == self.Status.SAVED:
            return False
            
        import boto3
        from django.conf import settings
        from urllib.parse import urlparse
        from datetime import datetime
        
        # 파일명 추출
        filename = self.s3_key.split('/')[-1]
        
        # 새 경로 생성 (saved/년/월/파일명)
        now = datetime.now()
        new_key = f'saved/{now.year}/{now.month:02d}/{filename}'
        
        # S3 클라이언트 생성
        s3 = boto3.client(
            's3',
            aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
            region_name=settings.AWS_S3_REGION_NAME
        )
        
        # S3에서 파일 복사
        copy_source = {
            'Bucket': settings.AWS_STORAGE_BUCKET_NAME,
            'Key': self.s3_key
        }
        
        try:
            s3.copy_object(
                Bucket=settings.AWS_STORAGE_BUCKET_NAME,
                CopySource=copy_source,
                Key=new_key
            )
            
            # 기존 파일 삭제
            s3.delete_object(
                Bucket=settings.AWS_STORAGE_BUCKET_NAME,
                Key=self.s3_key
            )
            
            # 모델 업데이트
            self.s3_key = new_key
            self.status = self.Status.SAVED
            self.save()
            return True
            
        except Exception as e:
            print(f"Error moving file in S3: {e}")
            return False

    def __str__(self):
        return f"Picture {self.picture_id} ({self.status})"


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
