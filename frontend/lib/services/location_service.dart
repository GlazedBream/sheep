import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/location_point.dart';
import '../models/event_point.dart';
import '../models/event_settings.dart';
import 'timeline_service.dart';
import 'event_detection_service.dart';


class LocationService {
  Timer? _timer;
  StreamSubscription<Position>? _locationSubscription;
  late final List<LocationPoint> _locationHistory = [];
  int _locationId = 0;
  final TimelineService _timelineService = TimelineService();
  final EventDetectionService _eventDetectionService = EventDetectionService();

  // 이벤트 감지 관련 변수
  DateTime _lastEventCheckTime = DateTime.now();
  Duration _eventCheckInterval = const Duration(minutes: 5);
  final List<EventPoint> _detectedEvents = [];

  // 싱글톤 패턴
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  // 초기화
  Future<void> initialize() async {
    await _timelineService.initialize();
    await _loadEventSettings();
  }

  // 이벤트 설정 로드
  Future<void> _loadEventSettings() async {
    await _eventDetectionService.loadSettings();
    final settings = await EventSettings.loadSettings();
    _eventCheckInterval = Duration(minutes: settings.checkIntervalMinutes);
  }

  // 현재 위치 가져오기
  Future<LocationPoint?> getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LocationPoint(
        id: _locationId++,
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
        altitude: position.altitude,
      );
    } catch (e) {
      print('위치를 가져오는 중 오류 발생: $e');
      return null;
    }
  }

  // 위치 추적 시작
  void startTracking(Function(LocationPoint) onLocationUpdate, Function(EventPoint) onEventDetected) async {
    // 타임라인 서비스 초기화
    await initialize();

    // 새 세션 시작
    if (_timelineService.getCurrentSession() == null) {
      await _timelineService.startNewSession('타임라인 ${DateTime.now().toString()}');
    }

    // 이전 구독이 있으면 취소
    _locationSubscription?.cancel();

    // 위치 스트림 구독
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // 10미터 이상 이동했을 때만 업데이트
      ),
    ).listen((Position position) async {
      // 현재 위치 저장
      LocationPoint currentLocation = LocationPoint(
        id: _locationId++,
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
        altitude: position.altitude,
      );

      _locationHistory.add(currentLocation);

      // 타임라인 서비스에 위치 추가
      await _timelineService.addLocationPoint(currentLocation);

      // 콜백 호출
      onLocationUpdate(currentLocation);

      // 이벤트 감지 (일정 간격으로)
      final settings = await EventSettings.loadSettings();
      if (settings.autoDetectEvents &&
          DateTime.now().difference(_lastEventCheckTime) >= _eventCheckInterval) {
        _checkForEvents(onEventDetected);
        _lastEventCheckTime = DateTime.now();
      }
    });
  }

  // 위치 추적 중지
  void stopTracking() async {
    _locationSubscription?.cancel();
    _locationSubscription = null;

    // 현재 세션 종료
    await _timelineService.endCurrentSession();
  }

  // 이벤트 감지
  void _checkForEvents(Function(EventPoint) onEventDetected) async {
    if (_locationHistory.isEmpty) return;

    // 이벤트 감지 서비스를 사용하여 이벤트 감지
    EventPoint? event = await _eventDetectionService.detectEvent(_locationHistory);

    if (event != null) {
      // 중복 이벤트 방지
      bool isDuplicate = _detectedEvents.any((e) =>
      _isNearby(e.latitude, e.longitude, event.latitude, event.longitude, 100) &&
          e.startTime.difference(event.startTime).inMinutes.abs() < 30);

      if (!isDuplicate) {
        _detectedEvents.add(event);

        // 타임라인 서비스에 이벤트 추가
        await _timelineService.addEventPoint(event);

        // 콜백 호출
        onEventDetected(event);
      }
    }
  }

  // 수동 이벤트 감지
  Future<EventPoint?> detectEventManually(List<LocationPoint> points) async {
    if (points.isEmpty) return null;

    // 이벤트 감지 서비스를 사용하여 이벤트 감지
    EventPoint? event = await _eventDetectionService.detectEvent(points);

    if (event != null) {
      // 중복 이벤트 방지
      bool isDuplicate = _detectedEvents.any((e) =>
      _isNearby(e.latitude, e.longitude, event.latitude, event.longitude, 100) &&
          e.startTime.difference(event.startTime).inMinutes.abs() < 30);

      if (!isDuplicate) {
        _detectedEvents.add(event);

        // 타임라인 서비스에 이벤트 추가
        await _timelineService.addEventPoint(event);

        return event;
      }
    }

    return null;
  }

  // 두 위치가 가까운지 확인
  bool _isNearby(double lat1, double lon1, double lat2, double lon2, double thresholdMeters) {
    double distance = calculateDistance(lat1, lon1, lat2, lon2);
    return distance <= thresholdMeters;
  }

  // 두 지점 간의 거리 계산 (미터)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    LocationPoint p1 = LocationPoint(
      id: -1,
      latitude: lat1,
      longitude: lon1,
      timestamp: DateTime.now(),
    );

    LocationPoint p2 = LocationPoint(
      id: -2,
      latitude: lat2,
      longitude: lon2,
      timestamp: DateTime.now(),
    );

    return p1.distanceTo(p2);
  }

  // 메모리 최적화
  void optimizeMemoryUsage() {
    // 위치 기록이 너무 많아지면 오래된 데이터 정리
    if (_locationHistory.length > 1000) {
      // 가장 최근 500개만 유지
      _locationHistory = List<LocationPoint>.from(_locationHistory.skip(_locationHistory.length - 500));
    }
  }

  // 감지된 이벤트 목록 가져오기
  List<EventPoint> getDetectedEvents() {
    return List.unmodifiable(_detectedEvents);
  }

  // 위치 기록 가져오기
  List<LocationPoint> getLocationHistory() {
    return List.unmodifiable(_locationHistory);
  }
}
