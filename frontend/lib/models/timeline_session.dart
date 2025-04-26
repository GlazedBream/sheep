import 'location_point.dart';
import 'event_point.dart';
import 'dart:math';

class TimelineSession {
  final String id;
  final DateTime startTime;
  DateTime endTime;
  final List<LocationPoint> locationPoints;
  final List<EventPoint> eventPoints;
  String name;

  TimelineSession({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.locationPoints,
    required this.eventPoints,
    required this.name,
  });

  // 새 세션 생성
  factory TimelineSession.create({required String name}) {
    final now = DateTime.now();
    return TimelineSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: now,
      endTime: now,
      locationPoints: [],
      eventPoints: [],
      name: name,
    );
  }

  // 위치 포인트 추가
  void addLocationPoint(LocationPoint point) {
    locationPoints.add(point);
    endTime = point.timestamp;
  }

  // 이벤트 포인트 추가
  void addEventPoint(EventPoint point) {
    eventPoints.add(point);
  }

  // 총 이동 거리 계산 (미터)
  double calculateTotalDistance() {
    if (locationPoints.length < 2) return 0;

    double totalDistance = 0;
    for (int i = 0; i < locationPoints.length - 1; i++) {
      totalDistance += _calculateDistance(
        locationPoints[i].latitude,
        locationPoints[i].longitude,
        locationPoints[i + 1].latitude,
        locationPoints[i + 1].longitude,
      );
    }

    return totalDistance;
  }

  // 두 지점 간의 거리 계산 (미터)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // 지구 반지름 (미터)
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
            cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
                sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  // 각도를 라디안으로 변환
  double _toRadians(double degree) {
    return degree * (pi / 180);
  }

  // JSON 변환을 위한 메서드
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'locationPoints': locationPoints.map((p) => p.toJson()).toList(),
      'eventPoints': eventPoints.map((p) => p.toJson()).toList(),
      'name': name,
    };
  }

  // JSON에서 객체 생성
  factory TimelineSession.fromJson(Map<String, dynamic> json) {
    return TimelineSession(
      id: json['id'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      locationPoints: (json['locationPoints'] as List)
          .map((p) => LocationPoint.fromJson(p))
          .toList(),
      eventPoints: (json['eventPoints'] as List)
          .map((p) => EventPoint.fromJson(p))
          .toList(),
      name: json['name'],
    );
  }
}
