import 'dart:math';
import '../models/location_point.dart';
import '../models/event_point.dart';
import '../models/event_settings.dart';

class EventDetectionService {
  // 싱글톤 패턴
  static final EventDetectionService _instance = EventDetectionService._internal();

  factory EventDetectionService() {
    return _instance;
  }

  EventDetectionService._internal();

  // 이벤트 ID 카운터
  int _eventId = 0;

  // 이벤트 설정
  EventSettings _settings = EventSettings();

  // 설정 로드
  Future<void> loadSettings() async {
    _settings = await EventSettings.loadSettings();
  }

  // 설정 업데이트
  void updateSettings(EventSettings settings) {
    _settings = settings;
  }

  // 이벤트 감지
  Future<EventPoint?> detectEvent(List<LocationPoint> points) async {
    // 설정 로드
    await loadSettings();

    if (points.length < 2) return null;

    // 가장 최근 위치
    LocationPoint latestPoint = points.last;

    // 최소 체류 시간 전 시간
    DateTime minDurationAgo = latestPoint.timestamp.subtract(
        Duration(minutes: _settings.minDurationMinutes)
    );

    // 최소 체류 시간 이후의 포인트들
    List<LocationPoint> recentPoints = points.where(
            (point) => point.timestamp.isAfter(minDurationAgo)
    ).toList();

    if (recentPoints.length < 2) return null;

    // 클러스터링 알고리즘을 사용하여 머무른 위치 감지
    List<LocationCluster> clusters = _clusterLocations(recentPoints, _settings.radiusMeters);

    // 가장 큰 클러스터 찾기
    LocationCluster? largestCluster;
    int maxPoints = 0;

    for (var cluster in clusters) {
      if (cluster.points.length > maxPoints) {
        maxPoints = cluster.points.length;
        largestCluster = cluster;
      }
    }

    // 클러스터가 없거나 포인트가 적으면 이벤트 없음
    if (largestCluster == null || largestCluster.points.length < recentPoints.length * 0.7) {
      return null;
    }

    // 클러스터 내 시간 범위 확인
    DateTime clusterStartTime = largestCluster.points
        .map((p) => p.timestamp)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    DateTime clusterEndTime = largestCluster.points
        .map((p) => p.timestamp)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    // 최소 체류 시간 이상 머물렀는지 확인
    int durationMinutes = clusterEndTime.difference(clusterStartTime).inMinutes;
    if (durationMinutes < _settings.minDurationMinutes) return null;

    // 이벤트 생성
    return EventPoint(
      id: _eventId++,
      latitude: largestCluster.centerLatitude,
      longitude: largestCluster.centerLongitude,
      startTime: clusterStartTime,
      endTime: clusterEndTime,
      title: '이벤트 $_eventId',
      description: '이 위치에서 $durationMinutes 분 동안 머물렀습니다.',
      category: _determineEventCategory(largestCluster, durationMinutes),
    );
  }

  // 위치 클러스터링 알고리즘
  List<LocationCluster> _clusterLocations(List<LocationPoint> points, double radiusMeters) {
    List<LocationCluster> clusters = [];

    for (var point in points) {
      bool addedToCluster = false;

      // 기존 클러스터에 추가 가능한지 확인
      for (var cluster in clusters) {
        double distance = _calculateDistance(
            point.latitude, point.longitude,
            cluster.centerLatitude, cluster.centerLongitude
        );

        if (distance <= radiusMeters) {
          cluster.addPoint(point);
          addedToCluster = true;
          break;
        }
      }

      // 새 클러스터 생성
      if (!addedToCluster) {
        clusters.add(LocationCluster(point));
      }
    }

    return clusters;
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

  // 이벤트 카테고리 결정
  String _determineEventCategory(LocationCluster cluster, int durationMinutes) {
    // 머문 시간에 따른 카테고리 결정
    if (durationMinutes > 180) { // 3시간 이상
      return 'long_stay';
    } else if (durationMinutes > 60) { // 1시간 이상
      return 'medium_stay';
    } else {
      return 'short_stay';
    }
  }
}

// 위치 클러스터 클래스
class LocationCluster {
  List<LocationPoint> points = [];
  double centerLatitude;
  double centerLongitude;

  LocationCluster(LocationPoint initialPoint)
      : points = [initialPoint],
        centerLatitude = initialPoint.latitude,
        centerLongitude = initialPoint.longitude;

  void addPoint(LocationPoint point) {
    points.add(point);
    _recalculateCenter();
  }

  void _recalculateCenter() {
    double sumLat = 0;
    double sumLng = 0;

    for (var point in points) {
      sumLat += point.latitude;
      sumLng += point.longitude;
    }

    centerLatitude = sumLat / points.length;
    centerLongitude = sumLng / points.length;
  }
}
