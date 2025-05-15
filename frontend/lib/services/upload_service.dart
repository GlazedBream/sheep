import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../helpers/auth_helper.dart';

class UploadService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Presigned URL 요청
  static Future<Map<String, dynamic>> getPresignedUrl(
      String fileName, String fileType) async {
    final response = await http.post(
      Uri.parse('$baseUrl/galleries/get-presigned-url/'),
      headers: await getAuthHeaders(),  // auth_helper의 함수 사용
      body: jsonEncode({
        'file_name': 'temp/$fileName',
        'file_type': fileType,
      }),
    );
    return jsonDecode(response.body);
  }

  // 파일 업로드
  static Future<void> uploadFile(
      String url, List<int> fileBytes, String contentType) async {
    await http.put(
      Uri.parse(url),
      headers: {'Content-Type': contentType},
      body: fileBytes,
    );
  }

  // 이미지 업로드 프로세스
  static Future<Map<String, dynamic>?> uploadImage(File imageFile) async {
    try {
      // 파일 정보 추출
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final fileType = 'image/${fileName.split('.').last}';

      // 1. Presigned URL 요청
      final presignedData = await getPresignedUrl(fileName, fileType);

      // 2. S3에 파일 업로드
      final fileBytes = await imageFile.readAsBytes();
      await uploadFile(
        presignedData['upload_url'],
        fileBytes,
        fileType,
      );

      // 3. 업로드 완료 알림 및 Picture 모델에 임시 레코드 생성
      final notifyResponse = await http.post(
        Uri.parse('$baseUrl/galleries/notify-upload/'),
        headers: await getAuthHeaders(),
        body: jsonEncode({
          's3_key': presignedData['s3_key'],
          'filename': fileName,
          'file_type': fileType,
        }),
      );

      if (notifyResponse.statusCode == 200) {
        final responseData = jsonDecode(notifyResponse.body);
        return {
          's3_key': responseData['s3_key'],
          'picture_id': responseData['picture_id'],
          'status': responseData['status'],
        };
      } else {
        print('이미지 알림 실패: ${notifyResponse.body}');
        return null;
      }
    } catch (e) {
      print('이미지 업로드 중 오류 발생: $e');
      return null;
    }
  }
}