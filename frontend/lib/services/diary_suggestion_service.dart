import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/auth_helper.dart';

class DiarySuggestionService {
  static const String baseUrl = 'http://10.0.2.2:8000/api/diaries';

  // 일기 제안 생성 요청
  static Future<Map<String, dynamic>> createDiarySuggestion({
    required String date,
    required String title,
    required String content,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/suggestions/');
      final headers = await getAuthHeaders();
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'date': date,
          'title': title,
          'content': content,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to create diary suggestion: ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error creating diary suggestion: $e',
      };
    }
  }

  // 작업 상태 확인 (폴링)
  static Stream<Map<String, dynamic>> checkTaskStatus(String taskId) async* {
    final url = Uri.parse('$baseUrl/suggestions/tasks/$taskId/');
    
    // 최대 30초 동안 1초 간격으로 폴링
    const maxAttempts = 30;
    int attempts = 0;
    
    while (attempts < maxAttempts) {
      try {
        final headers = await getAuthHeaders();
        final response = await http.get(url, headers: headers);
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          // 결과 반환
          yield {
            'success': true,
            'status': data['status'],
            'result': data['result'],
            'completed': data['status'] == 'SUCCESS' || data['status'] == 'FAILURE',
          };
          
          // 작업이 완료되면 종료
          if (data['status'] == 'SUCCESS' || data['status'] == 'FAILURE') {
            break;
          }
        } else {
          yield {
            'success': false,
            'error': 'Failed to check task status: ${response.statusCode}',
            'details': response.body,
          };
          break;
        }
      } catch (e) {
        yield {
          'success': false,
          'error': 'Error checking task status: $e',
        };
        break;
      }
      
      // 1초 대기 후 재시도
      await Future.delayed(const Duration(seconds: 1));
      attempts++;
    }
    
    // 최대 시도 횟수 초과
    if (attempts >= maxAttempts) {
      yield {
        'success': false,
        'error': 'Task status check timed out after $maxAttempts attempts',
      };
    }
  }

  // 일기 제안 생성 및 상태 모니터링
  static Stream<Map<String, dynamic>> createAndMonitorDiarySuggestion({
    required String date,
    required String title,
    required String content,
  }) async* {
    // 1. 일기 제안 생성 요청
    final createResponse = await createDiarySuggestion(
      date: date,
      title: title,
      content: content,
    );

    if (!createResponse['success']) {
      yield createResponse;
      return;
    }

    final taskId = createResponse['data']?['task_id'];
    if (taskId == null) {
      yield {
        'success': false,
        'error': 'No task ID returned from server',
      };
      return;
    }

    // 2. 작업 상태 모니터링
    yield* checkTaskStatus(taskId);
  }
}
