import io
import base64
import textwrap
from PIL import Image
from dotenv import load_dotenv
from openai import OpenAI

# 설정값
SCALEDOWN = 6
OPENAI_TEMPERATURE = 0.5
MAX_TOKENS = 500

# 환경변수 및 클라이언트 초기화
load_dotenv()
client = OpenAI()

def compress_image(image_path, scaledown=SCALEDOWN):
    img = Image.open(image_path)
    new_size = (int(img.width / scaledown), int(img.height / scaledown))
    img = img.resize(new_size, resample=Image.LANCZOS)
    img = img.convert("RGB")
    buffer = io.BytesIO()
    img.save(buffer, format="JPEG")
    return base64.b64encode(buffer.getvalue()).decode("utf-8")

def image_to_caption(image_path, event_data):
    b64_img = compress_image(image_path)

    system_prompt = textwrap.dedent(
        f"""\ 
        너는 사진 속 상황을 묘사하는 이미지 캡션 전문가야.

        이 사진을 보고 아래 조건을 지키면서 캡션을 작성해줘:

        [작성 조건]
        - 사진 속 키워드: {', '.join(event_data.get("keywords", ["키워드 없음"]))}
        - 사물, 인물, 배경, 상황을 자연스럽고 사실적으로 묘사해
        - 문장은 문법적으로 완결된 자연스러운 문장으로 작성하고, '같다', '인 듯하다'와 같은 불확실한 표현은 피해
        - 사진에서 보이는 것들을 명확하게 묘사해

        [금지 사항 ❌]
        - 사진 속 텍스트나 글자에 대한 언급
        - 사진이 회전되어 있다는 기술적 정보
        - 날짜, 시간, 계절 등을 직접적으로 언급하거나 추측하지 마
        """
    )

    response = client.chat.completions.create(
        model="gpt-4-turbo-2024-04-09",
        messages=[
            {"role": "system", "content": system_prompt},
            {
                "role": "user",
                "content": [
                    {
                        "type": "image_url",
                        "image_url": {"url": f"data:image/jpeg;base64,{b64_img}"},
                    }
                ],
            },
        ],
        max_tokens=MAX_TOKENS,
    )
    caption = response.choices[0].message.content
    return caption

def process_event(event):
    captions = []
    for image_path in event.get("images", []):
        caption = image_to_caption(image_path, event)
        captions.append(caption)

    return {
        "event_id": event.get("id", 0),
        "captions": captions,
        "place": event.get("place", "알 수 없는 장소"),
        "emotion": event.get("emotion", "알 수 없는 감정"),
        "keywords": event.get("keywords", ["키워드 없음"]),
        "start_time": event.get("start_time", "시간 정보 없음"),
    }
