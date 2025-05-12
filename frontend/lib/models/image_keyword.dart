import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

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
  final String openaiKey = dotenv.env['OPENAI_API_KEY']!;

  static Future<File> assetToFile(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${assetPath.split('/').last}');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      return file;
    } catch (e) {
      print("❌ Failed to load asset: $e");
      rethrow;
    }
  }

  Future<ImageKeywordResult?> extract(File imageFile) async {
    final base64Image = base64Encode(await imageFile.readAsBytes());
    final gptResponse = await _generateKeywordsFromImage(base64Image);

    if (gptResponse == null) return null;

    final caption = gptResponse["caption"];
    final keywordsEn = List<String>.from(gptResponse["keywords"]);
    final keywordsKo = await _translateKeywords(keywordsEn);

    return ImageKeywordResult(
      caption: caption,
      keywordsEn: keywordsEn,
      keywordsKo: keywordsKo,
    );
  }

  Future<Map<String, dynamic>?> _generateKeywordsFromImage(String base64Image) async {
    print("📢 _generateKeywordsFromImage 함수 진입 완료"); // 최상단 확인 로그
    print("API 키: ${dotenv.env['OPENAI_API_KEY']}");

    final prompt = '''
이 이미지에 대해 오늘 하루를 기록하는 **영어 다이어리 문장**을 한 줄 작성해줘.
단, 문장 안에 이미지의 핵심 대상이 구체적으로 담기게 해줘.

그리고 이미지에서 보이는 음식이나 장소에 대해 가장 핵심적인 요리명이나 장소명을 중심으로 영어 키워드 3개를 추출해줘.
결과는 설명 없이 아래 JSON 형태로만 출력해줘:

{
  "caption": "감성적이면서 정보도 담긴 영어 문장",
  "keywords": ["구체적 키워드1", "구체적 키워드2", "구체적 키워드3"]
}
''';

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $openaiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "gpt-4o",
        "messages": [
          {
            "role": "user",
            "content": [
              {"type": "text", "text": prompt},
              {
                "type": "image_url",
                "image_url": {
                  "url": "data:image/jpeg;base64,$base64Image",
                  "detail": "auto"
                }
              }
            ]
          }
        ],
        "max_tokens": 300
      }),
    );

    if (response.statusCode == 200) {
      // 응답 확인 및 디버깅
      final content = json.decode(utf8.decode(response.bodyBytes))["choices"][0]["message"]["content"];
      print("API 응답 내용: $content");  // 응답 로그 추가

      final match = RegExp(r'{.*}', dotAll: true).firstMatch(content);
      if (match != null) {
        return json.decode(match.group(0)!);
      }
    } else {
      // API 요청 실패 시 오류 출력
      print('API 요청 실패: ${response.statusCode}');
      print('응답 내용: ${response.body}');
    }


    return null;
  }

  Future<List<String>> _translateKeywords(List<String> keywords) async {
    final prompt = '''
다음 영어 키워드 리스트를 자연스럽게 한국어로 번역해줘:
$keywords

반드시 아래 형식처럼 JSON 리스트로만 응답해:
["번역된단어1", "번역된단어2", "번역된단어3"]
''';

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $openaiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "gpt-4o",
        "messages": [
          {"role": "user", "content": prompt}
        ],
        "max_tokens": 100
      }),
    );

    if (response.statusCode == 200) {
      final content = json.decode(utf8.decode(response.bodyBytes))["choices"][0]["message"]["content"];
      final match = RegExp(r'\[.*\]', dotAll: true).firstMatch(content);
      if (match != null) {
        return List<String>.from(json.decode(match.group(0)!));
      }
    }

    return [];
  }
}