import 'dart:io';

class UploadService {
  // S3 업로드 대신 로컬 파일 경로를 반환하도록 수정
  static Future<Map<String, dynamic>?> uploadImage(File imageFile) async {
    try {
      // 로컬 파일 경로를 그대로 반환
      return {
        's3_key': imageFile.path, // 실제 S3 키 대신 로컬 경로 사용
        'picture_id': DateTime.now().millisecondsSinceEpoch, // 임시 ID 생성
        'status': 'saved', // 상태를 saved로 설정
      };
    } catch (e) {
      print('로컬 이미지 처리 중 오류 발생: $e');
      return null;
    }
  }
}