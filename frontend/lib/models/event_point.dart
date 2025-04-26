import 'package:flutter/material.dart';

class EventPoint {
  final int id;
  final double latitude;
  final double longitude;
  final DateTime startTime;
  final DateTime endTime;
  String title;
  String description;
  final String? category;
  final Map<String, dynamic>? metadata;
  String? address;
  List<String> tags = [];

  EventPoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.startTime,
    required this.endTime,
    required this.title,
    required this.description,
    this.category,
    this.metadata,
    this.address,
  });

  // 이벤트 지속 시간 (분)
  int get durationMinutes => endTime.difference(startTime).inMinutes;

  // 이벤트 카테고리에 따른 색상
  Color get categoryColor {
    switch (category) {
      case 'long_stay':
        return Colors.red;
      case 'medium_stay':
        return Colors.orange;
      case 'short_stay':
        return Colors.yellow;
      default:
        return Colors.blue;
    }
  }

  // 이벤트 카테고리에 따른 아이콘
  IconData get categoryIcon {
    switch (category) {
      case 'long_stay':
        return Icons.home;
      case 'medium_stay':
        return Icons.restaurant;
      case 'short_stay':
        return Icons.coffee;
      default:
        return Icons.location_on;
    }
  }

  // 태그 추가
  void addTag(String tag) {
    if (!tags.contains(tag)) {
      tags.add(tag);
    }
  }

  // 태그 제거
  void removeTag(String tag) {
    tags.remove(tag);
  }

  // 주소 설정
  void setAddress(String newAddress) {
    address = newAddress;
  }

  // JSON 변환을 위한 메서드
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'title': title,
      'description': description,
      'category': category,
      'metadata': metadata,
      'address': address,
      'tags': tags,
    };
  }

  // JSON에서 객체 생성
  factory EventPoint.fromJson(Map<String, dynamic> json) {
    EventPoint event = EventPoint(
      id: json['id'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      title: json['title'],
      description: json['description'],
      category: json['category'],
      metadata: json['metadata'],
      address: json['address'],
    );

    if (json['tags'] != null) {
      event.tags = List<String>.from(json['tags']);
    }

    return event;
  }
}