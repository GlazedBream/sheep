// 📄 diary_generate_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String?> generateDiaryText({
  required String token,
  required String timeline,
  required List<String> keywords,
  required int emotionId,
}) async {
  final url = Uri.parse("http://<YOUR_BACKEND_IP>/api/diaries/generate/");

  final response = await http.post(
    url,
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({
      "timeline": timeline,
      "keywords": keywords,
      "emotion_id": emotionId,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data["generated_text"];
  } else {
    print("Error: ${response.body}");
    return null;
  }
}
