import 'package:flutter/material.dart';

/// 🔁 공통 이모지 다이얼로그
Future<String?> showEmojiDialog(BuildContext context, {required String title}) async {
  final List<String> emojis = ['😀', '😐', '😢', '😡', '😍', '😴'];

  return await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: emojis.map((emoji) {
            return GestureDetector(
              onTap: () => Navigator.of(context).pop(emoji),
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            );
          }).toList(),
        ),
      );
    },
  );
}

/// ✅ 오늘 감정 선택용 다이얼로그
Future<String?> showTodayEmotionDialog(BuildContext context) {
  return showEmojiDialog(context, title: '오늘 기분을 선택해주세요?');
}

/// ✅ 일정 감정 선택용 다이얼로그
Future<String?> showEventEmotionDialog(BuildContext context) {
  return showEmojiDialog(context, title: '이 일정에서의 기분은 어떠셨나요?');
}

/// 이모지를 숫자 emotion_id로 변환하는 함수
int convertEmojiToId(String emoji) {
  switch (emoji) {
    case '😀': return 1;
    case '😐': return 2;
    case '😢': return 3;
    case '😡': return 4;
    case '😍': return 5;
    case '😴': return 6;
    default: return 0; // 알 수 없는 이모지일 경우 0으로 처리
  }
}

String convertIdToEmoji(int id) {
  switch (id) {
    case 1: return '😀';
    case 2: return '😐';
    case 3: return '😢';
    case 4: return '😡';
    case 5: return '😍';
    case 6: return '😴';
    default: return '❓';
  }
}