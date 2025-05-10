from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from drf_spectacular.utils import extend_schema, OpenApiParameter, OpenApiTypes
from django.conf import settings
import boto3
import uuid
from datetime import datetime
from .models import Picture
from .serializers import (
    GetPresignedUrlRequestSerializer,
    GetPresignedUrlResponseSerializer,
    NotifyUploadRequestSerializer,
    NotifyUploadResponseSerializer,
    ConfirmImageRequestSerializer,
    ConfirmImageResponseSerializer,
)


class GetPresignedUrlView(APIView):
    """
    API-G001: S3 Presigned URL 요청
    POST /api/galleries/get-presigned-url/

    200 OK: Presigned URL 발급 성공
    400 Bad Request: 요청 데이터가 유효하지 않음
    401 Unauthorized: 인증되지 않은 사용자
    """

    permission_classes = [IsAuthenticated]
    serializer_class = GetPresignedUrlRequestSerializer

    @extend_schema(
        request=serializer_class,
        responses={
            200: GetPresignedUrlResponseSerializer,
            400: OpenApiTypes.OBJECT,
            401: OpenApiTypes.OBJECT,
        },
    )
    def post(self, request):
        try:
            serializer = self.serializer_class(data=request.data)
            if not serializer.is_valid():
                return Response(
                    serializer.errors,
                    status=status.HTTP_400_BAD_REQUEST,
                )

            # 임시 업로드 폴더 생성
            temp_folder = f"temp_uploads/{str(uuid.uuid4())}/"
            s3_key = f"{temp_folder}{serializer.validated_data['file_name']}"

            # S3 클라이언트 생성
            s3 = boto3.client(
                "s3",
                aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
                aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
            )

            # Presigned URL 생성
            upload_url = s3.generate_presigned_url(
                "put_object",
                Params={
                    "Bucket": settings.AWS_STORAGE_BUCKET_NAME,
                    "Key": s3_key,
                    "ContentType": serializer.validated_data['file_type'],
                },
                ExpiresIn=3600,  # 1시간 유효
            )

            response_data = {
                "upload_url": upload_url,
                "s3_key": s3_key,
            }
            response_serializer = GetPresignedUrlResponseSerializer(data=response_data)
            response_serializer.is_valid(raise_exception=True)
            return Response(
                response_serializer.validated_data,
                status=status.HTTP_200_OK,
            )

        except Exception as e:
            return Response(
                {"message": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )


class NotifyUploadView(APIView):
    """
    API-G002: 임시 업로드 완료 알림
    POST /api/galleries/notify-upload/

    200 OK: 임시 업로드 완료 알림 성공
    400 Bad Request: 요청 데이터가 유효하지 않음
    401 Unauthorized: 인증되지 않은 사용자
    404 Not Found: S3 키가 존재하지 않음
    """

    permission_classes = [IsAuthenticated]
    serializer_class = NotifyUploadRequestSerializer

    @extend_schema(
        request=serializer_class,
        responses={
            200: NotifyUploadResponseSerializer,
            400: OpenApiTypes.OBJECT,
            401: OpenApiTypes.OBJECT,
            404: OpenApiTypes.OBJECT,
        },
    )
    def post(self, request):
        try:
            serializer = self.serializer_class(data=request.data)
            if not serializer.is_valid():
                return Response(
                    serializer.errors,
                    status=status.HTTP_400_BAD_REQUEST,
                )

            # S3 클라이언트 생성
            s3 = boto3.client(
                "s3",
                aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
                aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
            )

            # S3 키 존재 확인
            try:
                s3.head_object(
                    Bucket=settings.AWS_STORAGE_BUCKET_NAME,
                    Key=serializer.validated_data['s3_key'],
                )
            except s3.exceptions.NoSuchKey:
                return Response(
                    {"message": "S3 키가 존재하지 않습니다."},
                    status=status.HTTP_404_NOT_FOUND,
                )

            response_data = {
                "message": "사진 임시 업로드에 성공했습니다."
            }
            response_serializer = NotifyUploadResponseSerializer(data=response_data)
            response_serializer.is_valid(raise_exception=True)
            return Response(
                response_serializer.validated_data,
                status=status.HTTP_200_OK,
            )

        except Exception as e:
            return Response(
                {"message": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )


class ConfirmImageView(APIView):
    """
    API-G003: 사진 정식 등록
    POST /api/galleries/confirm-image/

    201 Created: 사진 정식 등록 성공
    400 Bad Request: 요청 데이터가 유효하지 않음
    401 Unauthorized: 인증되지 않은 사용자
    404 Not Found: S3 키가 존재하지 않음
    """

    permission_classes = [IsAuthenticated]
    serializer_class = ConfirmImageRequestSerializer

    @extend_schema(
        request=serializer_class,
        responses={
            201: ConfirmImageResponseSerializer,
            400: OpenApiTypes.OBJECT,
            401: OpenApiTypes.OBJECT,
            404: OpenApiTypes.OBJECT,
        },
    )
    def post(self, request):
        try:
            serializer = self.serializer_class(data=request.data)
            if not serializer.is_valid():
                return Response(
                    serializer.errors,
                    status=status.HTTP_400_BAD_REQUEST,
                )

            # S3 클라이언트 생성
            s3 = boto3.client(
                "s3",
                aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
                aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
            )

            # S3 키 존재 확인
            try:
                s3.head_object(
                    Bucket=settings.AWS_STORAGE_BUCKET_NAME,
                    Key=serializer.validated_data['s3_key'],
                )
            except s3.exceptions.NoSuchKey:
                return Response(
                    {"message": "S3 키가 존재하지 않습니다."},
                    status=status.HTTP_404_NOT_FOUND,
                )

            # 파일 정보 추출
            temp_folder, filename = serializer.validated_data['s3_key'].split("/")[-2:]
            file_type = filename.split(".")[-1]

            # 새 위치 생성
            new_key = f"uploads/{datetime.now().strftime('%Y/%m/%d')}/{filename}"

            # 파일 이동
            s3.copy_object(
                Bucket=settings.AWS_STORAGE_BUCKET_NAME,
                CopySource={
                    "Bucket": settings.AWS_STORAGE_BUCKET_NAME,
                    "Key": serializer.validated_data['s3_key'],
                },
                Key=new_key,
            )

            # 원본 파일 삭제
            s3.delete_object(
                Bucket=settings.AWS_STORAGE_BUCKET_NAME,
                Key=serializer.validated_data['s3_key'],
            )

            # Picture 모델 생성
            picture = Picture.objects.create(
                picture_content_url=f"{settings.AWS_S3_CUSTOM_DOMAIN}/{new_key}"
            )

            response_data = {
                "final_url": f"{settings.AWS_S3_CUSTOM_DOMAIN}/{new_key}",
                "picture_id": picture.picture_id,
            }
            response_serializer = ConfirmImageResponseSerializer(data=response_data)
            response_serializer.is_valid(raise_exception=True)
            return Response(
                response_serializer.validated_data,
                status=status.HTTP_201_CREATED,
            )

        except Exception as e:
            return Response(
                {"message": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )
