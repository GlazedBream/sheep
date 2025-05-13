import 'package:flutter/material.dart';
import 'emoji.dart'; // 감정 이모지 선택 다이얼로그
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '/theme/themed_scaffold.dart';
import '/theme/templates.dart';
import '/pages/event/event_detail_screen.dart';
import '/pages/review/review_page.dart';
import '/pages/mypage/mypage.dart';
import '/pages/calendarscreen.dart';
import 'diary_page.dart';
import 'emoji.dart';
import '/data/diary.dart';
import '../../theme/themed_scaffold.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:test_sheep/constants/location_data.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '/helpers/auth_helper.dart';

class Event {
  final int id;
  final DateTime time;
  final String title;
  final List<String> keywords;
  final List<String> memos;

  Event({
    required this.id,
    required this.time,
    required this.title,
    this.keywords = const [],
    this.memos = const [],
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      time: DateTime.parse(json['time']),
      title: json['title'],
      keywords:
          (json['keywords'] as List?)
              ?.map((e) => e['content'].toString())
              .toList() ??
          [],
      memos: (json['memos'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class WritePage extends StatefulWidget {
  final String emotionEmoji;
  final DateTime selectedDate;
  final Map<String, LatLng> locationMap = {
    "집": LatLng(37.5665, 126.9780),
    "이태원": LatLng(37.5340, 126.9940),
    "홍대": LatLng(37.5563, 126.9220),
    "한강": LatLng(37.5283, 126.9326), // 여의도 근처
    "명동": LatLng(37.5609, 126.9862),
    "종로": LatLng(37.5716, 126.9768), // Jongno 저녁 장소
  };

  // const WritePage({
  WritePage({
    // test button 용
    super.key,
    this.emotionEmoji = '😀', // test button 용
    DateTime? selectedDate, // test button 용
  }) : selectedDate = selectedDate ?? DateTime.now();

  @override
  State<WritePage> createState() => _WritePageState();
}

class _WritePageState extends State<WritePage> {
  String emotionEmoji = '😀';
  Set<int> savedEventIndices = {}; // 저장된 타임라인 인덱스들

  List<LatLng> _polylineCoordinates = [];
  List<Marker> _markers = [];
  GoogleMapController? _mapController;
  List<int> eventIdSeries = []; // 전역에서 선언

  final List<String> gpsTimeline = [
    "09:00 - 이태원에서 아침식사",
    "12:00 - 홍대에서 서점 방문",
    "16:30 - 한강에서 산책",
    "18:00 - 명동에서 쇼핑",
    "19:30 - 집에서 휴식",
    "20:30 - 종로에서 친구들과 저녁식사",
    "22:30 - 귀가",
  ];

  late final String _emojiKey;

  @override
  void initState() {
    super.initState();
    _emojiKey =
        'selectedEmotionEmoji_${widget.selectedDate.toIso8601String().split('T').first}';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _checkFirstLaunch();

      await convertTimelineToLatLng(); // timeline 먼저 처리
      await _loadSavedEvents(); // 그 다음 저장 정보 로딩
      await loadEventIdMap();

      setState(() {}); // 둘 다 끝난 뒤 UI 갱신
    });
  }

  Future<List<LatLng>> convertTimelineToLatLng() async {
    Map<String, LatLng> locationMap = {
      "집": LatLng(37.5665, 126.9780),
      "이태원": LatLng(37.5340, 126.9940),
      "홍대": LatLng(37.5563, 126.9220),
      "한강": LatLng(37.5283, 126.9326), // 여의도 근처
      "명동": LatLng(37.5609, 126.9862),
      "종로": LatLng(37.5716, 126.9768), // Jongno 저녁 장소
    };

    List<LatLng> coords = [];
    List<Marker> markerList = [];

    for (String entry in gpsTimeline) {
      locationMap.forEach((place, coord) {
        if (entry.contains(place)) {
          coords.add(coord);

          markerList.add(
            Marker(
              markerId: MarkerId(place + entry),
              position: coord,
              infoWindow: InfoWindow(
                title: entry.split(" - ").first, // 시간 부분
                snippet: place, // 장소명
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          );
        }
      });
    }

    setState(() {
      _polylineCoordinates = coords;
      _markers = markerList; // ✅ 마커 상태도 함께 저장
    });

    if (_polylineCoordinates.isNotEmpty) {
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_polylineCoordinates.first, 12),
      );
    }

    return coords;
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey =
        'hasLaunchedEmotionDialog_${widget.selectedDate.toIso8601String().split('T').first}';
    final emojiKey = _emojiKey;

    String? savedEmoji = prefs.getString(emojiKey);
    if (savedEmoji != null) {
      setState(() {
        emotionEmoji = savedEmoji;
      });
    }

    // 다이얼로그 첫 실행 여부 확인
    bool? hasLaunched = prefs.getBool(dateKey);
    if (hasLaunched == null || hasLaunched == false) {
      // ✅ 이모지 다이얼로그 직접 호출
      String? result = await showTodayEmotionDialog(context);
      if (result != null) {
        setState(() {
          emotionEmoji = result;
        });
        await prefs.setString(emojiKey, result);
      }

      await prefs.setBool(dateKey, true);
    }
  }

  String extractLocation(String timelineText) {
    for (String location in locationMap.keys) {
      if (timelineText.contains(location)) {
        return location;
      }
    }
    return "Unknown"; // 예외처리
  }

  Future<void> _loadSavedEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final dateKeyPrefix =
        widget.selectedDate.toIso8601String().split('T').first;

    Set<int> loadedIndices = {};
    for (int i = 0; i < gpsTimeline.length; i++) {
      final key = 'event_saved_${dateKeyPrefix}_$i';
      if (prefs.getBool(key) == true) {
        loadedIndices.add(i);
        print('==> 저장된 일정: ${gpsTimeline[i]}');
      }
    }

    setState(() {
      savedEventIndices = loadedIndices;
    });
  }

  LatLng getLatLngFromTimelineItem(String timelineItem) {
    final Map<String, LatLng> locationMap = {
      "집": LatLng(37.5665, 126.9780),
      "이태원": LatLng(37.5340, 126.9940),
      "홍대": LatLng(37.5563, 126.9220),
      "한강": LatLng(37.5283, 126.9326),
      "명동": LatLng(37.5609, 126.9862),
      "종로": LatLng(37.5716, 126.9768),
    };

    final parts = timelineItem.split(' - ');
    if (parts.length < 2) return locationMap["집"]!;

    final desc = parts[1];
    final place = desc.split('에서').first.trim();

    return locationMap[place] ?? locationMap["집"]!;
  }

  Future<void> _saveEventIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = widget.selectedDate.toIso8601String().split('T').first;
    await prefs.setBool('event_saved_${dateKey}_$index', true);

    setState(() {
      if (!savedEventIndices.contains(index)) {
        savedEventIndices.add(index);
      }
    });
  }

  Future<void> _selectTodayEmotion(
    BuildContext context,
    String emojiKey,
  ) async {
    // 1. 다이얼로그 열기
    String? selected = await showTodayEmotionDialog(context);

    // 2. 선택되었을 경우에만 처리
    if (selected != null) {
      // 3. 상태 업데이트
      setState(() {
        emotionEmoji = selected;
      });

      // 4. SharedPreferences 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(emojiKey, selected);
    }
  }

  Future<void> saveTimelineToServer(List<int> eventIdSeries) async {
    final storage = FlutterSecureStorage();
    final url = Uri.parse('http://10.0.2.2:8000/api/events/timeline/');
    final token = await storage.read(key: 'accessToken');
    print(widget.selectedDate);

    final body = {
      "date": widget.selectedDate.toIso8601String().split('T').first,
      "event_ids_series": List.generate(
        gpsTimeline.length,
        (i) => eventIdMap[i] ?? -1,
      ),
    };
    print('POST body: ${jsonEncode(body)}');

    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ 타임라인 저장 완료');
      } else {
        print('❌ 저장 실패: ${response.body}');
      }
    } catch (e) {
      print('⛔ 예외 발생: $e');
    }
  }

  Map<int, int> eventIdMap = {}; // {timelineIndex: eventId}

  // 네비게이션 처리 메서드
  void _onNavigationTap(int index) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CalendarScreen()),
        );
        break;
      case 1:
      // 현재 페이지이므로 아무 동작 안 함
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyPageScreen()),
        );
        break;
    }
  }


  void _onEventSaved(int index, int event_id) async {
    await _saveEventIndex(index);
    setState(() {
      eventIdMap[index] = event_id;
    });
    await saveEventIdMap();
  }

  Future<void> saveEventIdMap() async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = widget.selectedDate.toIso8601String().split('T').first;
    // Map<int, int> → Map<String, int>로 변환해서 저장
    final mapStr = eventIdMap.map((k, v) => MapEntry(k.toString(), v));
    await prefs.setString('eventIdMap_$dateKey', jsonEncode(mapStr));
  }

  Future<void> loadEventIdMap() async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = widget.selectedDate.toIso8601String().split('T').first;
    final str = prefs.getString('eventIdMap_$dateKey');
    if (str != null) {
      final map = jsonDecode(str) as Map<String, dynamic>;
      setState(() {
        eventIdMap = map.map((k, v) => MapEntry(int.parse(k), v as int));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      title: "📅 Today's Timeline",
      currentIndex: 1,  // 현재 선택된 탭 인덱스
      onTap: _onNavigationTap,
      navItems: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Review',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.timeline),
          label: 'Timeline',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'My Page',
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Selected Date: ${widget.selectedDate.toLocal().toString().split(' ')[0]}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  "Today's emotion: $emotionEmoji",
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                // IconButton(
                //   icon: const Icon(Icons.edit, size: 20),
                //   tooltip: 'Edit Emotion',
                //   onPressed: () => _showEmotionDialog(context, _emojiKey),
                // ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  tooltip: 'Edit Emotion',
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    String? result = await showTodayEmotionDialog(context);
                    if (result != null) {
                      setState(() {
                        emotionEmoji = result;
                      });
                      await prefs.setString(_emojiKey, result);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.hardEdge,
              child: GoogleMap(
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                },
                initialCameraPosition: CameraPosition(
                  target:
                      _polylineCoordinates.isNotEmpty
                          ? _polylineCoordinates.first
                          : LatLng(37.5665, 126.9780), // 기본 중심
                  zoom: 12,
                ),
                polylines: {
                  Polyline(
                    polylineId: PolylineId('route'),
                    points: _polylineCoordinates,
                    color: Colors.blue,
                    width: 5,
                  ),
                },
                markers: Set<Marker>.from(_markers), // ✅ 마커 표시
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "📍 Timeline",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              itemCount: gpsTimeline.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final isSaved = savedEventIndices.contains(
                  index,
                ); // 해당 일정이 저장되었는지 확인
                return GestureDetector(
                  onTap: () async {
                    final selectedTimeline = gpsTimeline[index];
                    String location = extractLocation(gpsTimeline[index]);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => EventDetailScreen(
                              selectedDate: widget.selectedDate,
                              emotionEmoji: emotionEmoji,
                              timelineItem: selectedTimeline,
                              selectedLatLng: getLatLngFromTimelineItem(
                                gpsTimeline[index],
                              ),
                              location: location,
                              index: index,
                            ),
                      ),
                    );
                    if (result != null && result is int) {
                      _onEventSaved(index, result); // result는 저장된 eventId (int)
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isSaved ? Colors.blue[50] : null, // 저장된 일정은 색상 변경
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            isSaved
                                ? Colors.blue
                                : Colors.grey[300]!, // 저장된 일정은 파란색 테두리
                        width: isSaved ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.place,
                        color:
                            isSaved
                                ? Colors.blue
                                : Colors.grey, // 저장된 일정 아이콘 색상 변경
                      ),
                      title: Text(
                        gpsTimeline[index],
                        style: TextStyle(
                          color:
                              isSaved
                                  ? Colors.blue[800]
                                  : Colors.black87, // 저장된 일정 텍스트 색상 변경
                          fontWeight:
                              isSaved ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final coords = await convertTimelineToLatLng();
                  final markers = {
                    Marker(
                      markerId: MarkerId('start'),
                      position: LatLng(37.5665, 126.9780),
                    ),
                    Marker(
                      markerId: MarkerId('end'),
                      position: LatLng(37.5700, 126.9820),
                    ),
                  };

                  final timelinePath = [
                    LatLng(37.5665, 126.9780),
                    LatLng(37.5670, 126.9795),
                    LatLng(37.5700, 126.9820),
                  ];

                  final newEntry = DiaryEntry(
                    date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    text: "자동 생성된 다이어리 요약 내용입니다.",
                    tags: ["자동요약", "타임라인"],
                    photos: [],
                    latitude: 37.5665,
                    longitude: 126.9780,
                    timeline: coords,
                    markers: markers,
                    cameraTarget: LatLng(37.5675, 126.9800),
                    emotionEmoji: emotionEmoji,
                  );

                  List<int> eventIdSeries = List.generate(
                    gpsTimeline.length,
                    (i) => eventIdMap[i] ?? -1, // 저장 안 된 일정은 -1로 표시
                  );
                  print('eventIdMap: $eventIdMap');
                  print('eventIdSeries: $eventIdSeries');
                  await saveTimelineToServer(eventIdSeries);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => DiaryPage(
                            entry: newEntry,
                            emotionEmoji: newEntry.emotionEmoji,
                            date: newEntry.date,
                          ),
                    ),
                  );
                },
                icon: const Icon(Icons.book),
                label: const Text("Go to the Diary"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue[200],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
