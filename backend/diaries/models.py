from django.db import models
from django.conf import settings
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.apps import apps
from events.models import Keyword

# Keyword 모델은 문자열로 참조
User = get_user_model()

class DiaryKeyword(models.Model):
    diary = models.ForeignKey('Diary', on_delete=models.CASCADE)
    keyword = models.ForeignKey('events.Keyword', on_delete=models.CASCADE)
    is_selected = models.BooleanField(default=True)
    is_auto_generated = models.BooleanField(default=False)

    class Meta:
        db_table = 'diary_keyword'
        verbose_name = "일기 키워드"
        verbose_name_plural = "일기 키워드 목록"
        unique_together = (('diary', 'keyword'),)

    def __str__(self):
        return f"Keyword {self.keyword} for Diary {self.diary.id}"

class Diary(models.Model):
    diary_id = models.AutoField(primary_key=True)
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    diary_date = models.DateField(default=timezone.now)
    final_text = models.TextField()
    keywords = models.ManyToManyField(
        'events.Keyword',
        through='DiaryKeyword',
        related_name='diaries'
    )
    emotion_id = models.ForeignKey('Emotion', on_delete=models.SET_NULL, null=True, blank=True)
    timeline_sent = models.JSONField(null=True, blank=True)
    markers = models.JSONField(null=True, blank=True)
    camera_target = models.JSONField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "일기"
        verbose_name_plural = "일기 목록"

    def __str__(self):
        return f"{self.final_text}"

    def add_keyword(self, keyword_content, is_selected=True, is_auto_generated=False):
        """
        Diary에 키워드를 추가합니다.
        
        Args:
            keyword_content (str): 추가할 키워드의 내용
            is_selected (bool): 사용자가 선택한 키워드인지 여부
            is_auto_generated (bool): 자동 생성된 키워드인지 여부
        """
        
        # 키워드 생성
        keyword, created = Keyword.objects.get_or_create(content=keyword_content)
        
        # DiaryKeyword 생성
        DiaryKeyword.objects.create(
            diary=self,
            keyword=keyword,
            is_selected=is_selected,
            is_auto_generated=is_auto_generated
        )
        
        return keyword

    def remove_keyword(self, keyword_content):
        """
        Diary에 키워드를 제거합니다.
        
        Args:
            keyword_content (str): 제거할 키워드의 내용
        """
        
        # 키워드 조회
        keyword = Keyword.objects.filter(content=keyword_content).first()
        
        if keyword:
            # DiaryKeyword 중개 테이블에서 데이터 제거
            self.keywords.remove(keyword)

EMOTION_CHOICES = [
    ('Happy', '😀'),
    ('Neutral', '😐'),
    ('Sad', '😔'),
    ('Angry', '😡'),
    ('Excited', '🤩'),
    ('Sleepy', '😴'),
]

EMOTION_LABEL_TO_ID = {
    'Happy': 1,
    'Neutral': 2,
    'Sad': 3,
    'Angry': 4,
    'Excited': 5,
    'Sleepy': 6,
}

EMOTION_ID_TO_LABEL = {v: k for k, v in EMOTION_LABEL_TO_ID.items()}

EMOTION_EMOJI_MAP = {
    1: '😀',
    2: '😐',
    3: '😔',
    4: '😡',
    5: '🤩',
    6: '😴',
}

class Emotion(models.Model):
    emotion_label = models.CharField(max_length=50, unique=True)
    emoji = models.CharField(max_length=4, default='😀')  # 이모지 문자열
    order = models.IntegerField(default=0)  # 표시 순서

    def __str__(self):
        return f"{self.emoji} {self.emotion_label}"

    @classmethod
    def get_initial_data(cls):
        """초기 데이터 생성"""
        return [
            {'emotion_label': 'Happy', 'emoji': '😀', 'order': 1},
            {'emotion_label': 'Neutral', 'emoji': '😐', 'order': 2},
            {'emotion_label': 'Sad', 'emoji': '😔', 'order': 3},
            {'emotion_label': 'Angry', 'emoji': '😡', 'order': 4},
            {'emotion_label': 'Excited', 'emoji': '🤩', 'order': 5},
            {'emotion_label': 'Sleepy', 'emoji': '😴', 'order': 6},
        ]

