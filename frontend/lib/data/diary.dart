import 'package:flutter/material.dart';

class Diary {
  final String id;
  final String date; // "yyyy-MM-dd" 형식
  final String text;
  final List<String> tags;
  final List<String> photos;

  Diary({
    required this.id,
    required this.date,
    required this.text,
    required this.tags,
    required this.photos
  });

  factory Diary.empty() {
    return Diary(
      id: UniqueKey().toString(), // 임시로 UniqueKey로 고유 id 생성
      date: DateTime.now().toIso8601String().split('T').first, // yyyy-MM-dd 형태로 변환
      text: '',
      tags: [],
      photos: [],
    );
  }
}