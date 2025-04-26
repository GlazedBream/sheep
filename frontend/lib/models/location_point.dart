import 'dart:math';

class LocationPoint {
  final int id;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final double? altitude;

  LocationPoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
    this.speed,
    this.heading,
    this.altitude,
  });

  // 두 위치 간의 거리 계산 (미터)
  double distanceTo(LocationPoint other) {
    const double earthRadius = 6371000; // 지구 반지름 (미터)
    double dLat = _toRadians(other.latitude - latitude);
    double dLon = _toRadians(other.longitude - longitude);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
            cos(_toRadians(latitude)) * cos(_toRadians(other.latitude)) *
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
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'accuracy': accuracy,
      'speed': speed,
      'heading': heading,
      'altitude': altitude,
    };
  }

  // JSON에서 객체 생성
  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      id: json['id'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      timestamp: DateTime.parse(json['timestamp']),
      accuracy: json['accuracy'],
      speed: json['speed'],
      heading: json['heading'],
      altitude: json['altitude'],
    );
  }
}
