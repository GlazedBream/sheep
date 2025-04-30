import 'package:flutter/material.dart';
import 'emoji.dart'; // 감정 이모지 선택 다이얼로그
import 'package:shared_preferences/shared_preferences.dart';
import '/pages/event/event_detail_screen.dart';
import '/pages/review/review_page.dart';
import '/pages/mypage/mypage.dart';
import '/data/diary_data.dart';
import '/pages/calendarscreen.dart';
import 'diary_page.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class WritePage extends StatefulWidget {
  final String emotionEmoji;
  final DateTime selectedDate;

  // const WritePage({
  WritePage({ // test button 용
    super.key,
    // required this.emotionEmoji,
    // required this.selectedDate,
    this.emotionEmoji = '😀', // test button 용
    DateTime? selectedDate, // test button 용
  }) : selectedDate = selectedDate ?? DateTime.now();

  @override
  State<WritePage> createState() => _WritePageState();
}

class _WritePageState extends State<WritePage> {
  String emotionEmoji = '😀';
  Set<int> savedEventIndices = {}; // 저장된 타임라인 인덱스들

  final List<String> gpsTimeline = [
    "09:00 - Breakfast at Itaewon",
    "10:00 - Café at Gangnam",
    "11:30 - Bookstore in Hongdae",
    "12:30 - Samsung Station Meeting",
    "14:00 - Lunch near COEX",
    "15:00 - Walk at Han River",
    "17:00 - Shopping at Myeongdong",
    "18:00 - Home",
    "20:00 - Dinner with friends",
    "22:00 - Back home",
  ];

  late final String _emojiKey;

  @override
  void initState() {
    super.initState();
    _emojiKey = 'selectedEmotionEmoji_${widget.selectedDate.toIso8601String().split('T').first}';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstLaunch();
      _loadSavedEvents();
    });
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = 'hasLaunchedEmotionDialog_${widget.selectedDate.toIso8601String().split('T').first}';
    final emojiKey = _emojiKey;

    String? savedEmoji = prefs.getString(emojiKey);
    if (savedEmoji != null) {
      setState(() {
        emotionEmoji = savedEmoji;
      });
    }

    bool? hasLaunched = prefs.getBool(dateKey);
    if (hasLaunched == null || hasLaunched == false) {
      await _showEmotionDialog(context, emojiKey);
      await prefs.setBool(dateKey, true);
    }
  }

  Future<void> _loadSavedEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final dateKeyPrefix = widget.selectedDate.toIso8601String().split('T').first;

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

  Future<void> _saveEventIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = widget.selectedDate.toIso8601String().split('T').first;
    await prefs.setBool('event_saved_${dateKey}_$index', true);

    setState(() {
      savedEventIndices.add(index);
    });
  }

  Future<void> _showEmotionDialog(BuildContext context, String emojiKey) async {
    String? selectedEmoji = await showTodayEmotionDialog(context);
    if (selectedEmoji != null) {
      setState(() {
        emotionEmoji = selectedEmoji;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(emojiKey, selectedEmoji);
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
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  tooltip: 'Edit Emotion',
                  onPressed: () => _showEmotionDialog(context, _emojiKey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Container(
            //   height: 200,
            //   decoration: BoxDecoration(
            //     color: Colors.grey[300],
            //     borderRadius: BorderRadius.circular(12),
            //   ),
            //   child: const Center(child: Text("🗺 Map Placeholder")),
            // ),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.hardEdge,
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(37.5665, 126.9780), // 서울시청
                  zoom: 13,
                ),
                myLocationEnabled: true, // 현재 위치 표시
                myLocationButtonEnabled: true, // 위치 버튼
                zoomControlsEnabled: false, // 확대/축소 버튼 숨김
                onMapCreated: (GoogleMapController controller) {
                  // 컨트롤러 저장하려면 변수로 받아와야 함
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text("📍 Timeline", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailScreen(
                          selectedDate: widget.selectedDate,
                          emotionEmoji: emotionEmoji,
                          timelineItem: selectedTimeline,
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
                          fontWeight: isSaved ? FontWeight.bold : FontWeight.normal,
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
                onPressed: () {
                  final newEntry = DiaryEntry(
                    date: DateTime.now().toIso8601String().split('T').first,
                    // date: DateFormat('yyyy-MM-dd').format(DateTime.now()), // 오늘 날짜
                    text: "자동 생성된 다이어리 요약 내용입니다.", // ✅ 요약된 텍스트
                    tags: ["자동요약", "타임라인"],
                    photos: [], // 사진 없으면 빈 리스트
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DiaryPage(entry: newEntry),
                    ),
                  );
                },
                icon: const Icon(Icons.book),
                label: const Text("Go to the Diary"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue[200],
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                MaterialPageRoute(builder: (context) => CalendarScreen(
                )),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'My Page',
          ),
        ],
      ),
    );
  }
}