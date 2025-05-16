import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../constants/location_data.dart';

class ImageKeywordResult {
  final String caption;
  final List<String> keywordsEn;
  final List<String> keywordsKo;

  ImageKeywordResult({
    required this.caption,
    required this.keywordsEn,
    required this.keywordsKo,
  });

  @override
  String toString() {
    return 'Caption: $caption\nEnglish Keywords: $keywordsEn\nKorean Keywords: $keywordsKo';
  }
}

class ImageKeywordExtractor {
  static Future<File> assetToFile(String assetPath) async {
    try {
      // 이미지 경로가 assets/images/ 아래에 있는지 확인
      if (!assetPath.startsWith('assets/images/')) {
        throw Exception('Invalid asset path: $assetPath');
      }

      final byteData = await rootBundle.load(assetPath);
      if (byteData == null) {
        throw Exception('Asset not found: $assetPath');
      }

      // 에셋 경로를 그대로 반환
      return File(assetPath);
    } catch (e) {
      print("❌ Failed to load asset: $e");
      rethrow;
    }
  }

  Future<ImageKeywordResult?> extract(File imageFile) async {
    // 이미지 파일의 이름만 추출
    final fileName = imageFile.path.split('/').last;
    
    // Check if we have predefined keywords for this image
    // demoImageKeywords의 키는 'assets/images/demo03.jpg' 형식으로 저장되어 있음
    final keywordKey = 'assets/images/$fileName';
    if (demoImageKeywords.containsKey(keywordKey)) {
      final data = demoImageKeywords[keywordKey]!;
      return ImageKeywordResult(
        caption: data['caption'],
        keywordsEn: List<String>.from(data['keywords']),
        keywordsKo: _translateToKorean(List<String>.from(data['keywords'])),
      );
    }
    
    // For non-demo images, return default values
    return ImageKeywordResult(
      caption: 'A beautiful moment captured during the trip.',
      keywordsEn: ['scenery', 'memory', 'moment'],
      keywordsKo: ['풍경', '추억', '순간'],
    );
  }
  
  // Helper method to translate keywords to Korean (mocked)
  List<String> _translateToKorean(List<dynamic> keywords) {
    // This is a simple mapping for demo purposes
    final Map<String, String> translationMap = {
      'rail bike': '레일바이크',
      'scenic view': '경치 좋은 전망',
      'outdoor activity': '야외 활동',
      'train station': '기차역',
      'historical site': '역사적 장소',
      'rustic charm': '전통적 매력',
      'coffee': '커피',
      'dessert': '디저트',
      'cafe interior': '카페 인테리어',
      'cafe exterior': '카페 외관',
      'blue theme': '파란색 테마',
      'photogenic spot': '사진 명소',
      'alpaca': '알파카',
      'animal interaction': '동물과 교감',
      'feeding': '먹이주기',
      'pasture': '목초지',
      'animals': '동물들',
      'nature view': '자연 경관',
      'scenery': '풍경',
      'memory': '추억',
      'moment': '순간',
    };
    
    return keywords.map((kw) => translationMap[kw] ?? kw.toString()).cast<String>().toList();
  }
}
