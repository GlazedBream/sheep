import os
import base64
import glob
import json
from openai import OpenAI
from PIL import Image
from PIL.ExifTags import TAGS, GPSTAGS
import re
import time

start_time = time.time()
from dotenv import load_dotenv

load_dotenv()
api_key = os.getenv("OPENAI_API_KEY")
# client ="
client = OpenAI(api_key=api_key)

def encode_image_to_base64(image_path):
    with open(image_path, "rb") as image_file:
        return base64.b64encode(image_file.read()).decode('utf-8')

def extract_caption_and_keywords(image_path, keyword_count=5):
    try:
        base64_image = encode_image_to_base64(image_path)
        
        response = client.chat.completions.create(
            model="gpt-4o",
            messages=[
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": f"""이 이미지에 대해 오늘 하루를 기록하는 **영어 다이어리 문장**을 한 줄 작성해줘.
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

                            {{
                            "caption": "감성적이면서 정보도 담긴 영어 문장",
                            "keywords": ["구체적 키워드1", "구체적 키워드2", "구체적 키워드3"]
                            }}"""},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{base64_image}"
                            }
                        }
                    ]
                }
            ],
            max_tokens=300
        )
        
        return response.choices[0].message.content.strip()
    
    except Exception as e:
        return f"오류 발생: {e}"

def translate_keywords(keywords):
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

        # 리스트 형태가 정확히 포함돼 있으면 그 부분만 파싱
        match = re.search(r"\[.*?\]", content, re.DOTALL)
        if match:
            return json.loads(match.group())

        # 혹시 리스트가 아닌 경우, 쉼표로 파싱
        return [kw.strip() for kw in re.split(r"[,\n]", content) if kw.strip()]
    
    except Exception as e:
        print(f"번역 오류: {e}")
        return []

if __name__ == "__main__":
    image_paths = glob.glob("data/*.[jp][pn]g")

    if not image_paths:
        print("data 폴더에 이미지가 없습니다.")
    else:
        image_data = {}

        for path in image_paths:
            filename = os.path.basename(path)
            print(f"\n📷 처리 중: {filename}")
            result = extract_caption_and_keywords(path)
            print(f"🔑 원본 결과: {result}")

            if result.startswith("오류"):
                print(result)
                continue

            try:
                cleaned_result = re.sub(r"^```(?:json)?\n?|```$", "", result.strip())
                parsed_result = json.loads(cleaned_result)

                # 번역 추가
                translated = translate_keywords(parsed_result["keywords"])
                parsed_result["keywords_ko"] = translated

                image_data[filename] = parsed_result

                print(f" 번역된 키워드: {translated}")

            except json.JSONDecodeError:
                print(f" JSON 파싱 오류: {result}")

        output_path = "data/keywords_results.json"
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(image_data, f, indent=2, ensure_ascii=False)

        print("\n 모든 이미지 처리 완료! 결과가 keywords_results.json 파일에 저장되었습니다.")
        
        
        # 전체 키워드 취합
        all_keywords_ko = []

        for data in image_data.values():
            all_keywords_ko.extend(data.get("keywords_ko", []))

        # 중복 제거 및 정렬
        all_keywords_ko = sorted(list(set(all_keywords_ko)))

        summary = {
            "all_keywords_ko": all_keywords_ko
        }

        # 종합 키워드도 같이 저장
        output_combined_path = "data/keywords_summary.json"
        with open(output_combined_path, "w", encoding="utf-8") as f:
            json.dump(summary, f, indent=2, ensure_ascii=False)

        print("\n 전체 키워드가 keywords_summary.json 파일에 저장되었습니다.")
        
        end_time = time.time()
        print(f"실행 시간: {end_time - start_time:.2f}초")
