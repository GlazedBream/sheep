import 'package:flutter/material.dart';

/// 템플릿 정의
class DiaryTemplate {
  final String name;
  final Color appBarColor;
  final Color backgroundColor;
  final String imagePath;  // 이미지 경로 추가

  const DiaryTemplate({
    required this.name,
    required this.appBarColor,
    required this.backgroundColor,
    required this.imagePath,  // 이미지 경로를 초기화
  });
}

const defaultTemplate = DiaryTemplate(
  name: '흰색목장',
  appBarColor: Color(0xFF94DB6E),
  backgroundColor: Color(0xFFFDF6E6),
  imagePath: 'assets/profile_sheep/profile_white.png',  // 이미지 경로 추가
);

const purpleTemplate = DiaryTemplate(
  name: '보라목장',
  appBarColor: Color(0xFFB39DDB), // 라벤더톤 퍼플
  backgroundColor: Color(0xFFF1E6D7), // 이미지와 자연스럽게 어우러지는 따뜻한 아이보리
  imagePath: 'assets/profile_sheep/profile_purple.png',  // 이미지 경로 추가
);

const brownTemplate = DiaryTemplate(
  name: '갈색목장',
  appBarColor: Color(0xFF6D4C41),
  backgroundColor: Color(0xFFF5E1DA),
  imagePath: 'assets/profile_sheep/profile_brown.png',  // 이미지 경로 추가
);

const pinkTemplate = DiaryTemplate(
  name: '핑크목장',
  appBarColor: Color(0xFFF48FB1),
  backgroundColor: Color(0xFFFCF2DD),
  imagePath: 'assets/profile_sheep/profile_pink.png',  // 이미지 경로 추가
);

const List<DiaryTemplate> allTemplates = [
  defaultTemplate,
  brownTemplate,
  pinkTemplate,
  purpleTemplate,
];

/// Provider - 템플릿 전역 상태
class TemplateProvider with ChangeNotifier {
  DiaryTemplate _currentTemplate = defaultTemplate;

  DiaryTemplate get currentTemplate => _currentTemplate;

  void setTemplate(DiaryTemplate newTemplate) {
    _currentTemplate = newTemplate;
    notifyListeners();
  }
}
