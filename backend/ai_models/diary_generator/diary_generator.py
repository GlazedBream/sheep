from typing import List
import os
import textwrap
from langchain.prompts.chat import ChatPromptTemplate
from langchain_openai import ChatOpenAI
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()

OPENAI_TEMPERATURE = 0.5
MAX_TOKENS = 500

api_key = os.getenv("OPENAI_API_KEY")
chat_model = ChatOpenAI(temperature=OPENAI_TEMPERATURE, model_name="gpt-4-turbo-2024-04-09", openai_api_key=api_key)

# 데모 이미지 캡션 매핑
DEMO_IMAGE_CAPTIONS = {
    "demo01.jpg": "이 사진은 '춘천 김유정 레일바이크'에 위치한 동백꽃 소설 속 인물 점순이의 동상을 담고 있습니다. "
                "동상은 야외에 설치되어 있으며, 캐릭터의 표정을 사실적으로 표현해 인물의 생동감을 강조하고 있습니다. "
                "주변에는 나무와 풀들이 자연스럽게 어우러져 있어 시골 마을의 고요하고 따뜻한 분위기를 자아냅니다.",
                
    "demo02.jpg": "이 사진은 '춘천 김유정 레일바이크' 인근의 화원을 담고 있으며, 핑크뮬리가 넓게 퍼져 장관을 이루고 있습니다. "
                "뒤편에는 낮은 산들이 부드러운 실루엣으로 펼쳐져 있고, 맑고 파란 하늘이 전체 배경을 감싸며 풍경의 탁 트인 느낌을 더욱 강조해 줍니다.",
                
    "demo03.jpg": "이 사진은 춘천의 한 카페의 포토존을 보여줍니다. 설치된 건축 구조물은 높은 곳에 위치해 있으며, "
                "하얀색으로 깔끔하게 마무리되어 있습니다. 이 구조물은 전통적인 아치형 디자인을 현대적으로 해석한 것 같으며, "
                "정상에는 작은 장식적인 요소가 보입니다. 배경으로는 맑은 하늘이 펼쳐져 있으며, "
                "햇빛이 구조물을 밝게 비추고 있어 사진 촬영 장소로서 매력적인 환경을 제공합니다.",
                
    "demo04.jpg": "이 사진은 춘천의 한 카페에서 찍은 것으로 보입니다. 사진에는 잘 구워진 황금빛 크로와상 하나가 흰색 접시에 담겨 있으며, "
                "옆에는 나무 포크와 나이프가 놓여 있습니다. 둥근 나무 테이블 위에는 두 개의 파란 무늬가 있는 종이컵에 담긴 커피가 보이는데, "
                "한 컵은 카푸치노로 보이며 위에 초콜릿 소스로 격자 무늬 장식이 되어 있고, 다른 한 컵은 라떼로 보입니다. "
                "전체적인 배치와 조화로운 컬러가 포토존으로서의 매력을 더해주는 카페 분위기를 잘 나타내고 있습니다.",
                
    "demo05.jpg": "알파카들이 자연스러운 환경에서 평화롭게 지내는 모습이 담긴 이 사진은 몇몇 알파카들이 나무 울타리 안에서 "
                "구경오는 방문객들을 바라보고 있는 장면을 보여줍니다. 흙길과 녹색의 나무들이 배경에 있어 자연의 느낌을 더해줍니다. "
                "알파카 중 하나는 특히 카메라를 향해 고개를 들고 있는데, 그 모습이 귀엽고 친근감을 줍니다.",
                
    "demo06.jpg": "이 사진은 대형 알파카 캐릭터 조형물이 마음을 표현하는 하트 모양의 물체를 들고 있는 모습을 보여줍니다. "
                "이 밝은 표정의 알파카는 자연 속에서 평화로움과 친근함을 느끼게 하며, "
                "배경에는 푸른 하늘과 조그만 건물이 보여 자연스러운 환경 속에서 조화롭게 자리잡고 있습니다."
}

# 기본 캡션 (매핑에 없는 이미지에 사용)
DEFAULT_CAPTION = "이 사진은 여행 중 촬영된 장면을 담고 있습니다."


def get_demo_captions() -> List[str]:
    """DEMO_IMAGE_CAPTIONS에 들어있는 모든 캡션을 리스트로 반환합니다."""
    return list(DEMO_IMAGE_CAPTIONS.values())


def process_event(event: dict) -> dict:
    """이벤트 데이터를 처리하여 DEMO_IMAGE_CAPTIONS의 캡션을 모두 포함한 captions 반환.

    Args:
        event: 이벤트 데이터 (place, emotion, keywords 등 포함)

    Returns:
        dict: captions에 DEMO_IMAGE_CAPTIONS 값들만 포함된 이벤트 정보
    """
    captions = get_demo_captions()

    return {
        "event_id": event.get("id", 0),
        "captions": captions,
        "place": event.get("place", "알 수 없는 장소"),
        "emotion": event.get("emotion", "알 수 없는 감정"),
        "keywords": event.get("keywords", ["키워드 없음"]),
        "start_time": event.get("start_time", "시간 정보 없음"),
    }


def generate_diary(events: List[dict]) -> str:
    """이벤트 목록을 기반으로 일기를 생성합니다. 각 이벤트는 DEMO_IMAGE_CAPTIONS의 모든 캡션을 사용함.

    Args:
        events: 이벤트 목록

    Returns:
        str: 생성된 일기 내용
    """
    if not events:
        return "오늘은 특별한 일이 없었습니다."

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
        captions = get_demo_captions()
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