import 'package:flutter/material.dart';
import 'emoji.dart'; // 감정 이모지 선택 다이얼로그
import 'package:shared_preferences/shared_preferences.dart';
import '/pages/event/event_detail_screen.dart';
import '/pages/review/review_page.dart';
import '/pages/mypage/mypage.dart';
import '/pages/calendarscreen.dart';
import 'diary_page.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:test_sheep/constants/location_data.dart';

class WritePage extends StatefulWidget {
  final String emotionEmoji;
  final DateTime selectedDate;
  final Map<String, LatLng> locationMap = {
    "Home": LatLng(37.5665, 126.9780),
    "Itaewon": LatLng(37.5340, 126.9940),
    "Hongdae": LatLng(37.5563, 126.9220),
    "Han River": LatLng(37.5283, 126.9326), // 여의도 근처
    "Myeongdong": LatLng(37.5609, 126.9862),
    "Friends": LatLng(37.5716, 126.9768), // Jongno 저녁 장소
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

  final List<String> gpsTimeline = [
    "08:30 - 출발 from Home",
    "09:00 - Breakfast at Itaewon",
    "12:00 - Bookstore in Hongdae",
    "16:30 - Walk at Han River",
    "18:00 - Shopping at Myeongdong",
    "19:30 - Back home & rest",
    "20:30 - Dinner with Friends near Jongno",
    "22:30 - Final return home",
  ];

  late final String _emojiKey;

  @override
  void initState() {
    super.initState();
    _emojiKey =
        'selectedEmotionEmoji_${widget.selectedDate.toIso8601String().split('T').first}';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstLaunch();
      _loadSavedEvents();
      convertTimelineToLatLng(); // ✅ 좌표 불러오기
    });
  }

  Future<List<LatLng>> convertTimelineToLatLng() async {
    Map<String, LatLng> locationMap = {
      "Home": LatLng(37.5665, 126.9780),
      "Itaewon": LatLng(37.5340, 126.9940),
      "Hongdae": LatLng(37.5563, 126.9220),
      "Han River": LatLng(37.5283, 126.9326), // 여의도 근처
      "Myeongdong": LatLng(37.5609, 126.9862),
      "Friends": LatLng(37.5716, 126.9768), // Jongno 저녁 장소
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
      }
    }

    setState(() {
      savedEventIndices = loadedIndices;
    });
  }

  LatLng getLatLngFromTimelineItem(String timelineItem) {
    Map<String, LatLng> locationMap = {
      "Home": LatLng(37.5665, 126.9780),
      "Itaewon": LatLng(37.5340, 126.9940),
      "Hongdae": LatLng(37.5563, 126.9220),
      "Han River": LatLng(37.5283, 126.9326), // 여의도 근처
      "Myeongdong": LatLng(37.5609, 126.9862),
      "Friends": LatLng(37.5716, 126.9768), // Jongno 저녁 장소
    };
    String? extractPlaceName(String timelineItem) {
      // timelineItem 예: "08:30 - 출발 from Home"
      final regex = RegExp(r'from (\w+(?: \w+)*)'); // "from 장소명" 추출
      final match = regex.firstMatch(timelineItem);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
      return null;
    }

    final place = extractPlaceName(timelineItem);
    if (place != null && locationMap.containsKey(place)) {
      return locationMap[place]!;
    }
    // 기본 좌표 (예: 서울 시청)
    return LatLng(37.5665, 126.9780);
  }

  Future<void> _saveEventIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = widget.selectedDate.toIso8601String().split('T').first;
    await prefs.setBool('event_saved_${dateKey}_$index', true);

    setState(() {
      savedEventIndices.add(index);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📅 Today's Timeline"),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
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
                final isSaved = savedEventIndices.contains(index);
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
                            ),
                      ),
                    );
                    if (result == true) {
                      _saveEventIndex(index);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isSaved ? Colors.blue[50] : null,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSaved ? Colors.blue : Colors.grey[300]!,
                        width: isSaved ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.place,
                        color: isSaved ? Colors.blue : Colors.grey,
                      ),
                      title: Text(
                        gpsTimeline[index],
                        style: TextStyle(
                          color: isSaved ? Colors.blue[800] : Colors.black87,
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // 현재 페이지 인덱스 (예: 타임라인 페이지면 1)
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CalendarScreen()),
              );
              break;
            case 1:
              // 현재 페이지가 타임라인이므로 아무 동작도 하지 않음
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyPageScreen()),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Review',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timeline),
            label: 'Timeline',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'My Page'),
        ],
      ),
    );
  }
}
