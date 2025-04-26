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