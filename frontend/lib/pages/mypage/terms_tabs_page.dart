// 이용약관, 개인정보, AI방침을 탭으로 구분
import 'package:flutter/material.dart';

/// 1. 이용약관/개인정보동의서/AI처리방침 페이지
class TermsTabsPage extends StatefulWidget {
  const TermsTabsPage({super.key});

  @override
  State<TermsTabsPage> createState() => _TermsTabsPageState();
}

class _TermsTabsPageState extends State<TermsTabsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = ['이용약관', '개인정보동의서', 'AI처리방침'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildTabContent(String title) {
    String content = '';

    if (title == '이용약관') {
      content = '''
제1조 (목적)
본 약관은 Sheep Diary(이하 "회사")가 제공하는 일기 작성 및 관련 서비스(이하 "서비스")의 이용과 관련하여 회사와 회원 간의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.

제2조 (정의)
1. “회원”이란 회사와 서비스 이용계약을 체결하고 아이디(ID)를 부여받은 자를 말합니다.
2. “콘텐츠”란 회원이 업로드하거나 생성한 사진, 글, 키워드 등을 말합니다.
3. “AI 기능”이란 회사가 제공하는 자동 일기 작성, 감정 분석, 키워드 추출 등의 기능을 의미합니다.

제3조 (약관의 효력 및 변경)
회사는 본 약관을 서비스 초기 화면에 게시하며, 필요 시 관계 법령을 위배하지 않는 범위 내에서 약관을 변경할 수 있습니다.

제4조 (서비스의 제공 및 변경)
1. 회사는 다음과 같은 서비스를 제공합니다:
  - 자동 일기 생성 서비스
  - 사진 및 위치 기반 타임라인
  - 키워드/감정 분석 기능
2. 회사는 AI 기능의 품질 향상 및 개선을 위해 콘텐츠 일부를 분석할 수 있습니다.

제5조 (회원의 의무)
회원은 본인의 콘텐츠가 타인의 권리를 침해하지 않도록 하며, 회사의 허가 없이 서비스 관련 정보를 무단으로 복제, 유통, 판매해서는 안됩니다.

제6조 (계정 관리)
회원은 본인의 계정 정보를 안전하게 관리해야 하며, 제3자에게 공유해서는 안됩니다.

제7조 (서비스 중단)
회사는 서비스 운영상 정기 점검, 시스템 점검, 긴급 상황 등이 발생할 경우 서비스를 일시 중단할 수 있습니다.

(이하 생략)
      ''';
    } else if (title == '개인정보동의서') {
      content = '''
1. 수집하는 개인정보 항목
회사는 회원가입, 서비스 제공을 위해 다음의 정보를 수집합니다:
- 필수항목: 이메일, 비밀번호, 이름
- 선택항목: 프로필 사진, 위치 정보, 업로드 사진

2. 개인정보 수집 방법
- 회원 가입 시 직접 입력
- 사진 업로드 및 위치 정보 수집은 사용자의 동의 후 진행

3. 개인정보의 이용 목적
- AI 기능 제공(일기 작성, 키워드 추출 등)
- 계정 식별 및 관리
- 통계 및 서비스 개선

4. 개인정보의 보유 및 이용 기간
- 회원 탈퇴 시 지체 없이 파기
- 단, 관련 법령에 따라 보존이 필요한 경우에는 해당 기간 동안 저장

5. 개인정보 제3자 제공
- 회사는 회원의 개인정보를 원칙적으로 외부에 제공하지 않습니다. 단, 법령에 따른 경우는 예외입니다.

6. 이용자의 권리
- 회원은 언제든지 개인정보 열람, 수정, 삭제, 처리정지를 요구할 수 있습니다.
      ''';
    } else if (title == 'AI처리방침') {
      content = '''
1. 목적
Sheep Diary는 AI를 활용한 일기 작성 및 키워드 추출 기능을 제공하며, 이를 위해 사용자의 사진과 입력 콘텐츠를 분석합니다.

2. AI 활용 항목
- 업로드된 사진: 감정 추출, 키워드 식별 등에 활용
- 시간 및 위치 정보: 타임라인 분석을 통해 자동 일기 작성

3. 데이터 처리 방식
- 입력된 콘텐츠는 AI 모델의 응답 품질 개선에 사용될 수 있으며, 이 과정에서 비식별화 처리가 이루어집니다.
- 학습 목적의 데이터는 일정 기간 동안 암호화된 상태로 저장되며, 사용자의 동의 없이 외부에 제공되지 않습니다.

4. 이용자의 선택권
- 사용자는 AI 기능 사용에 대한 동의 여부를 선택할 수 있으며, 언제든지 설정에서 변경 가능합니다.

5. AI 오작동 및 책임
- AI가 자동으로 생성한 콘텐츠는 사용자의 최종 확인이 필요하며, 회사는 AI 오작동에 따른 피해에 대해 법적 책임을 지지 않습니다.
      ''';
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Text(
          content,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('정책 문서'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((title) => Tab(text: title)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((title) => _buildTabContent(title)).toList(),
      ),
    );
  }
}