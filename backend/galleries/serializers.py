from rest_framework import serializers
from drf_spectacular.utils import extend_schema

class GetPresignedUrlRequestSerializer(serializers.Serializer):
    file_name = serializers.CharField(
        max_length=255,
        required=True,
        help_text="S3에 업로드할 파일의 이름"
    )
    file_type = serializers.CharField(
        max_length=100,
        required=True,
        help_text="업로드할 파일의 MIME 타입"
    )

    class Meta:
        # DRF Spectacular 문서화
        extra_kwargs = {
            'file_name': {
                'example': 'event_photo1.jpg',
                'description': '업로드할 파일의 이름'
            },
            'file_type': {
                'example': 'image/jpeg',
                'description': '업로드할 파일의 MIME 타입'
            }
        }


class GetPresignedUrlResponseSerializer(serializers.Serializer):
    upload_url = serializers.URLField(
        help_text="S3에 파일을 업로드하기 위한 presigned URL"
    )
    s3_key = serializers.CharField(
        help_text="S3에 업로드될 파일의 키"
    )

    class Meta:
        extra_kwargs = {
            'upload_url': {
                'example': 'https://sheep-diary-photos.s3.ap-northeast-2.amazonaws.com/temp/uuid/event_photo1.jpg?AWSAccessKeyId=...'
            },
            's3_key': {'example': 'temp/uuid/event_photo1.jpg'}
        }


class NotifyUploadRequestSerializer(serializers.Serializer):
    s3_key = serializers.CharField(
        required=True,
        help_text="S3에 업로드된 파일의 키"
    )
    filename = serializers.CharField(
        max_length=255,
        required=True,
        help_text="업로드된 파일의 원래 이름"
    )
    file_type = serializers.CharField(
        max_length=100,
        required=True,
        help_text="업로드된 파일의 MIME 타입"
    )

    class Meta:
        extra_kwargs = {
            's3_key': {'example': 'temp/uuid/event_photo1.jpg'},
            'filename': {'example': 'event_photo1.jpg'},
            'file_type': {'example': 'image/jpeg'}
        }


class NotifyUploadResponseSerializer(serializers.Serializer):
    message = serializers.CharField(
        help_text="업로드 완료 메시지"
    )

    class Meta:
        extra_kwargs = {
            'message': {'example': '사진 임시 업로드에 성공했습니다.'}
        }


class ConfirmImageRequestSerializer(serializers.Serializer):
    s3_key = serializers.CharField(
        required=True,
        help_text="임시 업로드된 S3 키"
    )

    class Meta:
        extra_kwargs = {
            's3_key': {'example': 'temp/uuid/event_photo1.jpg'}
        }


class ConfirmImageResponseSerializer(serializers.Serializer):
    final_url = serializers.URLField(
        help_text="최종 저장된 이미지의 URL"
    )
    picture_id = serializers.IntegerField(
        help_text="생성된 사진의 ID"
    )

    class Meta:
        extra_kwargs = {
            'final_url': {
                'example': 'https://sheep-diary-photos.s3.ap-northeast-2.amazonaws.com/saved/2025/05/02/event_photo1.jpg'
            },
            'picture_id': {'example': 123}
        }
