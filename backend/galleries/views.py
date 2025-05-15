from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from drf_spectacular.utils import extend_schema, OpenApiTypes
from django.conf import settings
import boto3
from botocore.config import Config
from botocore.exceptions import ClientError
import os
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

def generate_presigned_url(bucket_name, object_name, content_type):
    """Generate a presigned URL for S3 upload"""
    s3_client = boto3.client(
        's3',
        aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
        aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
        region_name=settings.AWS_S3_REGION_NAME,
        config=Config(signature_version='s3v4')
    )
    try:
        response = s3_client.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': bucket_name,
                'Key': object_name,
                'ContentType': content_type
            },
            ExpiresIn=settings.AWS_S3_URL_EXPIRE
        )
        return response
    except ClientError as e:
        print(f"Error generating presigned URL: {e}")
        return None

class PresignedURLView(APIView):
    permission_classes = [IsAuthenticated]
    
    @extend_schema(
        request=GetPresignedUrlRequestSerializer,
        responses={200: GetPresignedUrlResponseSerializer},
        description="S3에 파일을 업로드하기 위한 presigned URL을 생성합니다."
    )
    def post(self, request):
        serializer = GetPresignedUrlRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(
                serializer.errors,
                status=status.HTTP_400_BAD_REQUEST
            )
        
        file_name = serializer.validated_data['file_name']
        file_type = serializer.validated_data['file_type']

        # 고유한 파일명 생성
        unique_id = str(uuid.uuid4())
        file_extension = os.path.splitext(file_name)[1]
        s3_key = f"temp/{unique_id}{file_extension}"

        presigned_url = generate_presigned_url(
            settings.AWS_STORAGE_BUCKET_NAME,
            s3_key,
            file_type
        )

        if not presigned_url:
            return Response(
                {"error": "Failed to generate presigned URL"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        response_data = {
            "upload_url": presigned_url,
            "s3_key": s3_key
        }
        response_serializer = GetPresignedUrlResponseSerializer(data=response_data)
        response_serializer.is_valid(raise_exception=True)
        return Response(response_serializer.data)

class NotifyUploadView(APIView):
    permission_classes = [IsAuthenticated]
    
    @extend_schema(
        request=NotifyUploadRequestSerializer,
        responses={200: NotifyUploadResponseSerializer},
        description="파일 업로드 완료를 서버에 알리고 Picture 모델에 임시 레코드를 생성합니다."
    )
    def post(self, request):
        serializer = NotifyUploadRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(
                serializer.errors,
                status=status.HTTP_400_BAD_REQUEST
            )
        
        s3_key = serializer.validated_data['s3_key']
        filename = serializer.validated_data['filename']
        file_type = serializer.validated_data['file_type']

        try:
            # Picture 모델에 임시 레코드 생성 (TEMP 상태로)
            from .models import Picture
            
            picture = Picture.objects.create(
                s3_key=s3_key,
                status=Picture.Status.TEMP,
                user=request.user,
                picture_caption=f"임시 저장된 이미지 - {filename}"
            )

            response_data = {
                "message": "사진 임시 업로드에 성공했습니다.",
                "picture_id": picture.picture_id,
                "s3_key": s3_key,
                "status": picture.status
            }
            
            response_serializer = NotifyUploadResponseSerializer(data=response_data)
            response_serializer.is_valid(raise_exception=True)
            return Response(response_serializer.data, status=status.HTTP_200_OK)
            
        except Exception as e:
            print(f"Error creating Picture record: {str(e)}")
            return Response(
                {"error": "이미지 레코드 생성 중 오류가 발생했습니다."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class ConfirmImageView(APIView):
    permission_classes = [IsAuthenticated]
    ALLOWED_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.gif'}
    
    @extend_schema(
        request=ConfirmImageRequestSerializer,
        responses={201: ConfirmImageResponseSerializer},
        description="임시로 업로드된 이미지를 최종 저장하고 데이터베이스에 등록합니다."
    )
    def post(self, request):
        serializer = ConfirmImageRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(
                serializer.errors,
                status=status.HTTP_400_BAD_REQUEST
            )
        
        temp_s3_key = serializer.validated_data['s3_key']

        # 임시 경로에서 실제 경로로 이동
        if not temp_s3_key.startswith('temp/'):
            return Response(
                {"error": "Invalid temp file path"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # 실제 저장 경로 생성 (예: saved/user_id/year/month/filename)
        user_id = request.user.id
        now = datetime.now()
        filename = os.path.basename(temp_s3_key)
        if os.path.splitext(filename)[1].lower() not in self.ALLOWED_EXTENSIONS:
            return Response({"error": "허용되지 않은 파일 형식입니다."}, status=400)

        final_s3_key = f"saved/{user_id}/{now.year}/{now.month:02d}/{filename}"

        # S3에서 파일 이동
        s3 = boto3.client(
            's3',
            aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
            region_name=settings.AWS_S3_REGION_NAME
        )

        try:
            # 파일 복사
            copy_source = {
                'Bucket': settings.AWS_STORAGE_BUCKET_NAME,
                'Key': temp_s3_key
            }
            s3.copy_object(
                Bucket=settings.AWS_STORAGE_BUCKET_NAME,
                CopySource=copy_source,
                Key=final_s3_key
            )
            
            # 임시 파일 삭제
            s3.delete_object(
                Bucket=settings.AWS_STORAGE_BUCKET_NAME,
                Key=temp_s3_key
            )

            # 데이터베이스에 저장
            picture = Picture.objects.create(
                picture_content_url=f"https://{settings.AWS_STORAGE_BUCKET_NAME}.s3.{settings.AWS_S3_REGION_NAME}.amazonaws.com/{final_s3_key}",
                s3_key=final_s3_key,
                user=request.user  # 현재 사용자 연결
            )

            response_data = {
                "final_url": picture.picture_content_url,
                "picture_id": picture.picture_id
            }
            response_serializer = ConfirmImageResponseSerializer(data=response_data)
            response_serializer.is_valid(raise_exception=True)
            return Response(
                response_serializer.data,
                status=status.HTTP_201_CREATED
            )

        except ClientError as e:
            print(f"Error moving file: {e}")
            return Response(
                {"error": "Failed to process image"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
