# ─── 기본 설정 ────────────────────────────────
import os
import io
import json
import base64
from datetime import datetime
from dotenv import load_dotenv

# ─── 이미지 및 EXIF 처리 ──────────────────────
from PIL import Image

# ─── OpenAI 및 LangChain ─────────────────────
from openai import OpenAI
from langchain_openai import ChatOpenAI
from langchain.prompts.chat import ChatPromptTemplate

# ─── 텍스트 정리 ─────────────────────────────
import textwrap

# ─── 설정값 ───────────────────────────────────
SCALEDOWN = 6
OPENAI_TEMPERATURE = 0.5
MAX_TOKENS = 500

# ─── API 키 로드 ──────────────────────────────
load_dotenv()
client = OpenAI()
chat_model = ChatOpenAI(temperature=OPENAI_TEMPERATURE)


# ─── 이미지 압축 함수 ────────────────────────
def compress_image(image_path, scaledown=SCALEDOWN):
    img = Image.open(image_path)
    new_size = (int(img.width / scaledown), int(img.height / scaledown))
    img = img.resize(new_size, resample=Image.LANCZOS)
    img = img.convert("RGB")
    buffer = io.BytesIO()
    img.save(buffer, format="JPEG")
    return base64.b64encode(buffer.getvalue()).decode("utf-8")


# ─── 단일 이미지 캡션 생성 ───────────────────
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


# ─── 단일 사건 처리 ───────────────────────────
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


# ─── 일기 생성 함수 ───────────────────────────
def generate_diary(events: list[dict]) -> str:
    event_summaries = []

    diary_prompt = ChatPromptTemplate.from_messages(
        [
            (
                "system",
                textwrap.dedent(
                    """\
                    너는 사실적이고 담백한 어조로 하루를 정리하는 일기 작가야.  
                    감정에 치우치지 않고, 사진에 담긴 상황과 분위기, 그날의 감정을 자연스럽게 설명해줘.

                    [작성 조건]
                    - 일상 사건들의 시각적 묘사(captions)와 함께 장소, 감정, 키워드 정보를 참고해서 너무 감성적이지 않게, 담백하고 솔직한 반말 일기체로 작성해줘.
                    - 모든 문장은 한국어 '~다'로 끝나는 형식을 지켜줘.
                    - 시간은 굳이 정확히 말하지 않아도 되고, 하루 일상의 흐름대로 써줘.
                    - 단순 나열이 아닌 하나의 흐름으로, 의미 있는 하루처럼 정리해줘.
                    - 문장이 도중에 끊기지 않고 매끄럽게 이어져야 해.
                    - 글 길이는 300~500자 정도로 맞춰줘.
                    """
                ),
            ),
            (
                "human",
                textwrap.dedent(
                    """\
                    다음은 오늘 하루 동안 있었던 일상 사건들의 정보야. 이걸 참고해서 일기 한 단락을 써줘.

                    [일상 사건 정보]
                    {events}
                    """
                ),
            ),
        ]
    )

    for event in events:
        captions = []
        for image_path in event.get("images", []):
            caption = image_to_caption(image_path, event)
            captions.append(caption)

        combined_caption = " ".join(captions)

        event_summaries.append(
            {
                "event_id": event.get("id", 0),
                "start_time": event.get("start_time", "시간 정보 없음"),
                "place": event.get("place", "알 수 없는 장소"),
                "emotion": event.get("emotion", "알 수 없는 감정"),
                "keywords": event.get("keywords", ["키워드 없음"]),
                "combined_caption": combined_caption,
            }
        )

    events_str = "\n".join(
        [
            f"""일상 사건 {event['event_id']}:
            - 시간: {event['start_time']}
            - 장소: {event['place']}
            - 감정: {event['emotion']}
            - 키워드: {', '.join(event['keywords'])}
            - 일상 사건 요약: {event['combined_caption']}"""
            for event in event_summaries
        ]
    )

    messages = diary_prompt.format_messages(events=events_str)
    diary = chat_model.invoke(messages).content
    return diary
