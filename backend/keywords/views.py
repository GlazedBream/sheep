import os
import base64
import boto3
import json
import tempfile
from botocore.exceptions import NoCredentialsError
from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from openai import OpenAI
from django.conf import settings
from .models import Event
from .serializers import EventSerializer

# Initialize OpenAI client
client = OpenAI(api_key=settings.OPENAI_API_KEY)

# Initialize S3 client
s3_client = boto3.client(
    's3',
    aws_access_key_id=settings.AWS_ACCESS_KEY_ID2,
    aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY2,
    region_name=settings.AWS_S3_REGION_NAME2
)

# S3 업로드 함수
def upload_to_s3(file_data, filename):
    """Upload a file to S3 bucket"""
    try:
        # Create a temporary file
        with tempfile.NamedTemporaryFile(delete=False) as temp_file:
            # Write the base64 decoded data to the temp file
            temp_file.write(base64.b64decode(file_data))
            temp_file_path = temp_file.name

        # Upload the temp file to S3
        s3_client.upload_file(
            temp_file_path,
            settings.AWS_STORAGE_BUCKET_NAME2,
            f'uploads/{filename}'
        )

        # Delete the temp file
        os.unlink(temp_file_path)

        # Return the S3 URL
        return f'https://{settings.AWS_STORAGE_BUCKET_NAME2}.s3.{settings.AWS_REGION2}.amazonaws.com/uploads/{filename}'

    except NoCredentialsError:
        return None

# 이미지에서 키워드 추출 함수
def extract_keywords_from_image(image_url):
    """Extract keywords from an image using OpenAI API"""
    try:
        response = client.chat.completions.create(
            model="gpt-4o",
            messages=[
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": """이 이미지에 대해 오늘 하루를 기록하는 **영어 다이어리 문장**을 한 줄 작성해줘.
                            단, 문장 안에 이미지의 핵심 대상(예: 유채꽃, 돈까스, 바닷가 산책 등)이 구체적으로 담기게 해줘.

                            그리고 이미지에서 보이는 음식이나 장소에 대해 가장 핵심적인 요리명이나 장소명을 중심으로 영어 키워드 3개를 추출해줘.
                            - 음식의 경우 개별 재료보다는 전체 요리명(예: kimchi nabe, bibimbap, bulgogi 등)을 우선시해줘.
                            - 단순히 재료만 나열하지 말고 요리의 전체적인 이름이나 종류를 포함해줘.
                            - 한국식 바베큐 같은 표현 말고 삼겹살 같은 구체적인 요리명을 사용해줘.
                            - 유채꽃 같은 경우 canola와 flower을 따로 번역하지 말고 함께 묶어서 "canola flower"로 번역해줘.
                            - 장소의 경우, 특정한 장소명(예: Eiffel Tower, Jeju Island 등)을 우선시해줘.
                            - 스카이워크 같은 사람들이 자주 쓰는 장소명은 영어로 번역해줘.
                            - 장소명은 구체적이고 고유한 이름을 사용해줘.
                            - sea로 나타내지 말고 jeju sea같은 구체적인 장소로 나타내줘.
                            - 장소명은 구체적이고 고유한 이름을 사용해줘.
                            - 너무 일반적인 단어(spicy, beautiful, yellow 등)는 빼고, 실제 사물에 가까운 구체적 단어를 포함해줘.
                            - 일시적 문신 같은 경우 판박이 처럼 사람들이 자주 쓰는 표현으로 번역해줘.

                            결과는 설명 없이 아래 JSON 형태로만 출력해줘:

                            {
                            "caption": "감성적이면서 정보도 담긴 영어 문장",
                            "keywords": ["구체적 키워드1", "구체적 키워드2", "구체적 키워드3"]
                            }"""},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": image_url
                            }
                        }
                    ]
                }
            ],
            max_tokens=300
        )

        content = response.choices[0].message.content.strip()

        # Clean and parse the JSON response
        cleaned_result = content.replace("```json", "").replace("```", "").strip()
        parsed_result = json.loads(cleaned_result)

        # 영어 키워드를 한국어로 번역
        parsed_result["keywords_ko"] = translate_keywords(parsed_result["keywords"])

        return parsed_result

    except Exception as e:
        print(f"Error extracting keywords: {str(e)}")
        return {"caption": "", "keywords": [], "keywords_ko": []}

# 키워드 한국어 번역 함수
def translate_keywords(keywords):
    """Translate English keywords to Korean"""
    try:
        prompt = f"""다음 영어 키워드 리스트를 자연스럽게 한국어로 번역해줘:
        {keywords}

        반드시 아래 형식처럼 JSON 리스트로만 응답해:
        ["번역된단어1", "번역된단어2", "번역된단어3"]
        다른 설명은 절대 하지 마."""

        response = client.chat.completions.create(
            model="gpt-4o",
            messages=[{"role": "user", "content": prompt}],
            max_tokens=200
        )

        content = response.choices[0].message.content.strip()

        # JSON 리스트만 추출
        import re
        match = re.search(r"\[.*?\]", content, re.DOTALL)
        if match:
            return json.loads(match.group())

        return json.loads(content)

    except Exception as e:
        print(f"Translation error: {str(e)}")
        return []

# 이미지 처리 API 엔드포인트
@api_view(['POST'])
def process_images(request):
    """Upload images to S3 and extract keywords"""
    try:
        # Get base64 encoded images
        images = request.data.get('images', [])

        if not images or len(images) == 0:
            return Response(
                {"error": "No images provided"},
                status=status.HTTP_400_BAD_REQUEST
            )

        results = []
        all_keywords = []

        for i, image_data in enumerate(images):
            # Upload image to S3
            filename = f"image_{i}_{request.data.get('user_id', 'unknown')}_{request.data.get('timestamp', '')}.jpg"
            s3_url = upload_to_s3(image_data, filename)

            if not s3_url:
                return Response(
                    {"error": "Failed to upload image to S3"},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )

            # Extract keywords from image
            keywords_data = extract_keywords_from_image(s3_url)

            # Collect results
            results.append({
                "image_url": s3_url,
                "caption": keywords_data.get("caption", ""),
                "keywords": keywords_data.get("keywords", []),
                "keywords_ko": keywords_data.get("keywords_ko", [])
            })

            # Collect all Korean keywords
            all_keywords.extend(keywords_data.get("keywords_ko", []))

        # Remove duplicates and sort keywords
        unique_keywords = sorted(list(set(all_keywords)))

        return Response({
            "results": results,
            "all_keywords_ko": unique_keywords
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response(
            {"error": str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

# 이벤트 생성 API 엔드포인트
@api_view(['POST'])
def create_event(request):
    """Create a new event"""
    serializer = EventSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
