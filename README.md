# 🐑 Sheep Diary — Flutter + Django + DRF + MySQL 프로젝트

---

## 📁 폴더 구조

```
sheep_diary/
├── frontend/         # Flutter 앱 (Flutter SDK 필수)
├── backend/          # Django + DRF 백엔드 서버
├── db/               # MySQL DB 초기 세팅
│   ├── schema/       # 테이블 생성 스크립트 (DDL)
│   └── seed/         # 더미 데이터 삽입 스크립트 (DML)
├── deploy/           # 배포
├── docs/             # 문서
├── .gitignore
└── README.md
```

.gitkeep 파일들은 폴더구조 유지를 위해 넣어놓았습니다. 깃 클론 후에는 삭제해도 됩니다.

## 🚀 개발 환경 설정 가이드

### 0. 깃 클론

```bash
# 터미널을 열고(cmd) 작업을 시작할 폴더로 이동합니다 (아래는 예시)
cd C:\Users\Admin\vsc_projects\sheep_diary

# 깃 클론 (마지막 마침표 잊지말것)
git clone https://github.com/GlazedBream/sheep.git .

# Visual Studio Code 실행 (마지막 마침표)
code .
```

### 1. 개인 브랜치 사용

```bash
# 현재 브랜치 확인
git branch

# 최신 main 브랜치 가져오기
git checkout main
git pull origin main

# 브랜치 생성 및 이동 (예: jym이라는 이름으로 생성)
git checkout -b jym

# 작업 후 git staging
git add .

# 커밋 메시지 작성
git commit -m "✨ 작업한 내용 요약"

# 원격 브랜치로 푸시
git push origin jym
```

#### 브랜치명은 본인의 이니셜이나 역할명으로 간결하게 만들어주세요.

### 2. Python Conda 환경 준비

```bash
# conda 가상환경 생성 (Python 3.10 기준)
conda create -n sheepdiary_env python=3.10
conda activate sheepdiary_env

# 필수 패키지 설치
cd backend # 가상환경 확인하고, backend 폴더로 이동합니다.
pip install -r requirements.txt
```

-   추가로, 이메일 인증번호 보관에 사용할 캐시DB Redis를 설치합니다.
-   https://github.com/microsoftarchive/redis/releases
-   Assets 제일 위의 msi파일 다운로드 후 설치, PATH 추가

---

### 3. Django + DRF 백엔드 개발 서버 실행

```bash
# backend 폴더로 이동
cd backend/

# DB 마이그레이션 실행
python manage.py makemigrations
python manage.py migrate

# 개발 서버 실행
python manage.py runserver
```

-   .env 파일은 별도로 팀 내부에서 공유합니다. Git에는 절대 업로드하지 마세요.
-   (.gitignore에 제외처리는 돼있으므로 복사 후에는 신경 안써도 됩니다.)

---

### 4. API 테스트 방법

개발 중인 API를 로컬에서 테스트하려면 다음과 같은 절차를 따릅니다.

### 예시: API-U001 — 앱 초기 사용자 상태 확인 — GET /api/users/me/daily-status/

#### 1. 서버 실행

```bash
cd backend/
python manage.py runserver
```

#### 2. http로 API 호출

```bash
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> fetchUserDailyStatus(String accessToken) async {
  const String baseUrl = 'http://127.0.0.1:8000'; // Android 에뮬레이터: 'http://10.0.2.2:8000'
  final String url = '$baseUrl/api/users/me/daily-status/';

  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken", // JWT 토큰
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      print("✅ API 응답:");
      print(data);
    } else {
      print("❌ 오류 발생: 상태 코드 ${response.statusCode}");
      print(response.body);
    }
  } catch (e) {
    print("❌ 네트워크 오류: $e");
  }
}
```

#### 3. 3. 예상 응답 예시

```bash
{
  "is_authenticated": true,
  "today_date": "2025-04-17",
  "emotion": "happy",
  "diary_exists": false
}
```

---

## 📌 참고 사항

-   `frontend`와 `backend`는 각각 독립적으로 실행
-   Django REST Framework로 Flutter 앱에 API 제공
-   `.env` 파일을 활용해 비밀 키 및 DB 비밀번호 등 민감 정보 분리 추천
-   `config/settings.py`에서 `ALLOWED_HOSTS`, `CORS`, `STATIC`, `MEDIA` 경로 등도 설정 필요

---

## ✅ 작업 우선순위 (예시)

1. [ ] DB 스키마 정의 및 seed SQL 작성
2. [ ] Django 모델 및 API 라우팅
3. [ ] Flutter UI 기본 화면 구성 (지도 + 일기 리스트)
4. [ ] 백업과 통신 연결 테스트 (REST API 호출)

---

## 👥 협업 방식

-   Git 브랜치 전략: `main`, `dev`, `feature/*`
-   커밋 메시지 컨벤션:
    -   `feat:` 기능 추가
    -   `fix:` 버그 수정
    -   `docs:` 문서 변경
    -   `refactor:` 리팩토링
    -   `test:` 테스트 코드 추가
-   Pull Request 기준: `dev`로 병합, 코드 리뷰 후 `main`으로 머지

---

## 📮 문의 및 이슈

> 디스코드 정보공유를 통해서 긴밀하게 공유
