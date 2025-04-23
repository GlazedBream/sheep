from django.db import models


class Event(models.Model):
    # event_id는 기본 키로 자동 생성됩니다.
    event_id = models.AutoField(primary_key=True)

    # Foreign Key 필드 정의
    # diary_id = models.ForeignKey("diaries.Diary", on_delete=models.CASCADE)
    # user_id = models.ForeignKey("users.User", on_delete=models.CASCADE)
    location_id = models.ForeignKey("Location", on_delete=models.CASCADE)

    # 타임스탬프 (시작 시간과 종료 시간)
    timestamp_st = models.DateTimeField()
    timestamp_end = models.DateTimeField()

    # 감정(Emotion)과 날씨(Weather)를 문자열로 저장
    event_emotion = models.CharField(max_length=10)  # Enum을 CharField로 대체
    weather = models.CharField(max_length=10)  # Enum을 CharField로 대체

    # 이벤트 선택 여부
    is_selected_event = models.BooleanField(default=False)

    # 생성일과 수정일
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Event {self.event_id} - {self.timestamp_st} to {self.timestamp_end}"


# class Keyword(models.Model):
#     # keyword_id는 기본 키로 자동 생성됩니다.
#     keyword_id = models.AutoField(primary_key=True)

#     # 키워드 콘텐츠와 출처
#     content = models.CharField(max_length=50)
#     source_type = models.CharField(
#         max_length=20,
#         choices=[("from_picture", "From Picture"), ("from_user", "From User")],
#     )

#     def __str__(self):
#         return self.content


# class EventKeyword(models.Model):
#     # 외래 키 설정 (Event와 Keyword 모델의 관계)
#     event_id = models.ForeignKey("Event", on_delete=models.CASCADE)
#     keyword_id = models.ForeignKey(Keyword, on_delete=models.CASCADE)

#     # 선택된 키워드 여부
#     is_selected_keyword = models.BooleanField(default=False)

#     # 복합 기본 키 설정
#     class Meta:
#         unique_together = ("event_id", "keyword_id")

#     def __str__(self):
#         return f"Event {self.event_id.event_id} - Keyword {self.keyword_id.content}"


class Location(models.Model):
    location_id = models.AutoField(primary_key=True)
    region_name = models.CharField(max_length=50)
    specific_name = models.CharField(max_length=100)
    longitude = models.DecimalField(max_digits=10, decimal_places=6)
    latitude = models.DecimalField(max_digits=10, decimal_places=6)

    def __str__(self):
        return f"{self.region_name}"
