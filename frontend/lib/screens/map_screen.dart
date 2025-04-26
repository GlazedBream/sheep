import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
// import '../services/location_service.dart';
import '../models/location_point.dart';
import '../models/event_point.dart';
import 'event_detail_screen.dart';
import 'event_settings_screen.dart';
// import '../services/timeline_service.dart';
// import '../widgets/timeline_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  NaverMapController? _mapCocntroller;
  final LocationService _loationService = LocationService();
  final TimelineService _timelineService = TimelineService();
  List<LocationPoint> _timelinePoints = [];
  List<EventPoint> _eventPoints = [];
  bool _isTracking = false;
  bool _showTimeline = true;
  MapType _currentMapType = MapType.Basic;

  // 지도 스타일 옵션
  final List<MapType> _mapTypes = [
    MapType.Basic,
    MapType.Navi,
    MapType.Satellite,
    MapType.Hybrid,
    MapType.Terrain,
  ];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.locationAlways,
    ].request();

    if (statuses[Permission.location]!.isGranted) {
      // 위치 권한이 허용되면 위치 추적 시작
      _startLocationTracking();
    } else {
      // 권한이 거부된 경우 사용자에게 알림
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('위치 권한이 필요합니다.')),
      );
    }
  }

  void _startLocationTracking() {
    setState(() {
      _isTracking = true;
    });

    _locationService.startTracking((point) {
      setState(() {
        _timelinePoints.add(point);
      });
      _drawTimeline();
    }, (eventPoint) {
      setState(() {
        _eventPoints.add(eventPoint);
      });
      _addEventMarker(eventPoint);

      // 이벤트 발생 알림
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('새 이벤트가 감지되었습니다: ${eventPoint.title}'),
          action: SnackBarAction(
            label: '보기',
            onPressed: () {
              _onMarkerTap(eventPoint);
            },
          ),
        ),
      );
    });
  }

  void _stopLocationTracking() {
    setState(() {
      _isTracking = false;
    });
    _locationService.stopTracking();
  }

  void _drawTimeline() {
    if (_mapController == null || _timelinePoints.length < 2 || !_showTimeline) return;

    // 이전 경로 삭제
    _mapController!.clearOverlays(type: NaverOverlayType.polyline);

    // 새 경로 그리기
    List<LatLng> polylinePoints = _timelinePoints.map((point) =>
        LatLng(point.latitude, point.longitude)).toList();

    _mapController!.addOverlay(
      NaverPolylineOverlay(
        id: 'timeline_path',
        coords: polylinePoints,
        width: 5,
        color: Colors.blue,
        capType: PolylineCapType.round,
        joinType: PolylineJoinType.round,
      ),
    );

    // 시작점과 현재 위치 마커 추가
    if (polylinePoints.isNotEmpty) {
      // 시작점 마커
      _mapController!.addOverlay(
        NaverMarker(
          id: 'start_point',
          position: polylinePoints.first,
          icon: const MarkerIcon(
            iconData: Icons.play_circle_filled,
            size: Size(30, 30),
            color: Colors.green,
          ),
        ),
      );

      // 현재 위치 마커
      _mapController!.addOverlay(
        NaverMarker(
          id: 'current_point',
          position: polylinePoints.last,
          icon: const MarkerIcon(
            iconData: Icons.my_location,
            size: Size(30, 30),
            color: Colors.blue,
          ),
        ),
      );
    }
  }

  void _addEventMarker(EventPoint eventPoint) {
    if (_mapController == null) return;

    _mapController!.addOverlay(
      NaverMarker(
        id: 'event_${eventPoint.id}',
        position: LatLng(eventPoint.latitude, eventPoint.longitude),
        icon: MarkerIcon(
          iconData: eventPoint.categoryIcon,
          size: const Size(40, 40),
          color: eventPoint.categoryColor,
        ),
        onClick: (marker) {
          _onMarkerTap(eventPoint);
        },
        infoWindow: InfoWindow(
          title: eventPoint.title,
          snippet: DateFormat('yyyy-MM-dd HH:mm').format(eventPoint.startTime),
        ),
      ),
    );
  }

  void _onMarkerTap(EventPoint eventPoint) async {
    // 이벤트 상세 페이지로 이동하고 결과 받기
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(eventPoint: eventPoint),
      ),
    );

    // 결과 처리
    if (result != null) {
      final bool wasUpdated = result['updated'] ?? false;
      final EventPoint updatedEvent = result['event'] ?? eventPoint;

      // 이벤트가 수정되었으면 지도 업데이트
      if (wasUpdated) {
        // 이벤트 목록에서 해당 이벤트 업데이트
        final index = _eventPoints.indexWhere((e) => e.id == updatedEvent.id);
        if (index != -1) {
          setState(() {
            _eventPoints[index] = updatedEvent;
          });
        }

        // 이벤트 마커 다시 그리기
        if (_mapController != null) {
          // 기존 마커 삭제
          _mapController!.clearOverlays(type: NaverOverlayType.marker);

          // 현재 위치 마커 다시 추가
          if (_timelinePoints.isNotEmpty) {
            _mapController!.addOverlay(
              NaverMarker(
                id: 'current_point',
                position: LatLng(
                  _timelinePoints.last.latitude,
                  _timelinePoints.last.longitude,
                ),
                icon: const MarkerIcon(
                  iconData: Icons.my_location,
                  size: Size(30, 30),
                  color: Colors.blue,
                ),
              ),
            );
          }

          // 모든 이벤트 마커 다시 추가
          for (var event in _eventPoints) {
            _addEventMarker(event);
          }
        }
      }
    }
  }

  void _toggleMapType() {
    // 다음 지도 유형으로 순환
    int currentIndex = _mapTypes.indexOf(_currentMapType);
    int nextIndex = (currentIndex + 1) % _mapTypes.length;

    setState(() {
      _currentMapType = _mapTypes[nextIndex];
    });

    if (_mapController != null) {
      _mapController!.setMapType(_currentMapType);
    }
  }

  void _moveToCurrentLocation() async {
    if (_mapController == null) return;

    LocationPoint? currentLocation = await _locationService.getCurrentLocation();
    if (currentLocation != null) {
      _mapController!.moveCamera(
        CameraUpdate.toCameraPosition(
          CameraPosition(
            target: LatLng(currentLocation.latitude, currentLocation.longitude),
            zoom: 15,
          ),
        ),
      );
    }
  }

  void _toggleTimeline() {
    setState(() {
      _showTimeline = !_showTimeline;
    });

    if (_showTimeline) {
      _drawTimeline();
    } else {
      if (_mapController != null) {
        _mapController!.clearOverlays(type: NaverOverlayType.polyline);
      }
    }
  }

  void _showTimelineInfo() {
    if (_timelinePoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('타임라인 데이터가 없습니다.')),
      );
      return;
    }

    // 시작 시간과 현재 시간
    DateTime startTime = _timelinePoints.first.timestamp;
    DateTime endTime = _timelinePoints.last.timestamp;

    // 이동 거리 계산
    double totalDistance = 0;
    for (int i = 0; i < _timelinePoints.length - 1; i++) {
      totalDistance += _locationService.calculateDistance(
        _timelinePoints[i].latitude,
        _timelinePoints[i].longitude,
        _timelinePoints[i + 1].latitude,
        _timelinePoints[i + 1].longitude,
      );
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('타임라인 정보'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('시작 시간: ${DateFormat('yyyy-MM-dd HH:mm').format(startTime)}'),
            const SizedBox(height: 8),
            Text('현재 시간: ${DateFormat('yyyy-MM-dd HH:mm').format(endTime)}'),
            const SizedBox(height: 8),
            Text('총 이동 거리: ${totalDistance.toStringAsFixed(2)} m'),
            const SizedBox(height: 8),
            Text('이벤트 수: ${_eventPoints.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  // 현재 타임라인 세션 정보 표시
  void _showCurrentSessionInfo() {
    final currentSession = _timelineService.getCurrentSession();

    if (currentSession == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현재 활성화된 타임라인 세션이 없습니다.')),
      );
      return;
    }

    final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final duration = DateTime.now().difference(currentSession.startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentSession.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('시작 시간: ${dateFormat.format(currentSession.startTime)}'),
            Text('현재 시간: ${dateFormat.format(DateTime.now())}'),
            Text('경과 시간: ${hours}시간 ${minutes}분'),
            Text('위치 데이터: ${currentSession.locationPoints.length}개'),
            Text('이벤트: ${currentSession.eventPoints.length}개'),
            Text('이동 거리: ${(currentSession.calculateTotalDistance() / 1000).toStringAsFixed(2)} km'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _endCurrentSession();
            },
            child: const Text('세션 종료'),
          ),
        ],
      ),
    );
  }

  // 현재 타임라인 세션 종료
  void _endCurrentSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('타임라인 세션 종료'),
        content: const Text('현재 타임라인 세션을 종료하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('종료'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _stopLocationTracking();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('타임라인 세션이 종료되었습니다.')),
      );
    }
  }

  // 새 타임라인 세션 시작
  void _startNewSession() async {
    final nameController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 타임라인 세션 시작'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '세션 이름',
            hintText: '예: 오늘의 여행',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('시작'),
          ),
        ],
      ),
    );

    if (confirmed == true && nameController.text.isNotEmpty) {
      // 이전 세션 종료
      if (_isTracking) {
        _stopLocationTracking();
      }

      // 새 세션 시작
      await _timelineService.startNewSession(nameController.text);
      _startLocationTracking();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('새 타임라인 세션 "${nameController.text}"이(가) 시작되었습니다.')),
      );
    }
  }

  // 수동 이벤트 감지
  void _detectEventManually() async {
    if (_timelinePoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('위치 데이터가 없습니다.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('이벤트 감지 중...')),
    );

    EventPoint? event = await _locationService.detectEventManually(_timelinePoints);

    if (event != null) {
      setState(() {
        _eventPoints.add(event);
      });
      _addEventMarker(event);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('새 이벤트가 감지되었습니다: ${event.title}'),
          action: SnackBarAction(
            label: '보기',
            onPressed: () {
              _onMarkerTap(event);
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('감지된 이벤트가 없습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('네이버 지도 타임라인'),
        actions: [
          IconButton(
            icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
            tooltip: _isTracking ? '추적 중지' : '추적 시작',
            onPressed: () {
              if (_isTracking) {
                _stopLocationTracking();
              } else {
                _startLocationTracking();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '새 타임라인 세션',
            onPressed: _startNewSession,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: '현재 세션 정보',
            onPressed: _showCurrentSessionInfo,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '이벤트 설정',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EventSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          NaverMap(
            onMapCreated: (controller) {
              setState(() {
                _mapController = controller;
              });

              // 현재 위치로 카메라 이동
              _moveToCurrentLocation();

              // 이벤트 마커 다시 그리기
              for (var event in _eventPoints) {
                _addEventMarker(event);
              }
            },
            options: NaverMapViewOptions(
              indoorEnable: true,
              locationButtonEnable: true,
              consumeSymbolTapEvents: false,
              mapType: _currentMapType,
            ),
          ),
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'map_type',
                  onPressed: _toggleMapType,
                  child: const Icon(Icons.layers),
                  tooltip: '지도 유형 변경',
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'my_location',
                  onPressed: _moveToCurrentLocation,
                  child: const Icon(Icons.my_location),
                  tooltip: '현재 위치로 이동',
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'toggle_timeline',
                  onPressed: _toggleTimeline,
                  child: Icon(_showTimeline ? Icons.timeline : Icons.timeline_outlined),
                  tooltip: '타임라인 표시/숨김',
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'detect_event',
                  onPressed: _detectEventManually,
                  child: const Icon(Icons.add_location),
                  tooltip: '수동 이벤트 감지',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stopLocationTracking();
    super.dispose();
  }
}
