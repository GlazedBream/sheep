import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/themed_scaffold.dart';
import '../write/diary_page.dart';
import 'package:provider/provider.dart';
import '../../data/diary_provider.dart';
import '../../data/diary.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '/helpers/auth_helper.dart';

class ReviewPage extends StatefulWidget {
  final DiaryEntry entry;
  final String date;
  final String emotionEmoji;

  const ReviewPage({
    super.key,
    required this.entry,
    required this.date,
    required this.emotionEmoji,
  });

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  bool showMap = true;
  int _selectedIndex = 1; // BottomNavigation 현재 탭 인덱스
  Map<String, dynamic>? diaryEntry;
  LatLng cameraTarget = const LatLng(37.5665, 126.9780); // 기본값
  List<LatLng> timelinePolyline = [];
  Set<Marker> markers = {};
  String emotionEmoji = '😊';

  @override
  void initState() {
    super.initState();
    emotionEmoji = widget.emotionEmoji;
    fetchDiaryData();
  }

  Future<void> fetchDiaryData() async {
    final formattedDate = widget.date;
    // print(formattedDate);// 이미 전달된 date 사용
    final url = Uri.parse(
      'http://10.0.2.2:8000/api/diaries/$formattedDate/',
    ); // API 엔드포인트 URL
    final headers = await getAuthHeaders();

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print(data);

        // ❗ diaryEntry로 먼저 세팅하지 않고 data에서 직접 파싱
        final target = LatLng(
          data['camera_target']['lat'],
          data['camera_target']['lng'],
        );

        final timeline =
            (data['timeline_sent'] as List).map<LatLng>((point) {
              return LatLng(point['lat'], point['lng']);
            }).toList();

        final markerSet =
            (data['markers'] as List).map<Marker>((marker) {
              return Marker(
                markerId: MarkerId(marker['id']),
                position: LatLng(marker['lat'], marker['lng']),
              );
            }).toSet();

        setState(() {
          diaryEntry = data;
          cameraTarget = target;
          timelinePolyline = timeline;
          markers = markerSet;
        });
      } else {
        print("2");
        setState(() {
          diaryEntry = null; // 데이터가 없으면 null로 처리
        });
      }
    } catch (e) {
      print("3");
      setState(() {
        diaryEntry = null; // 예외 처리
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      title: "📖 Diary Review",
      currentIndex: null,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          tooltip: 'Edit Diary',
          onPressed: () {
            if (diaryEntry != null) {
              DiaryEntry parsedDiary = DiaryEntry(
                date: diaryEntry!['date'] ?? '',
                text: diaryEntry!['finalText'] ?? '',
                tags: List<String>.from(diaryEntry!['keywords'] ?? []),
                photos: List<String>.from(diaryEntry!['photos'] ?? []),
                latitude: (diaryEntry!['latitude'] ?? 0.0).toDouble(),
                longitude: (diaryEntry!['longitude'] ?? 0.0).toDouble(),
                timeline:
                    (diaryEntry!['timeline'] as List<dynamic>? ?? []).map((e) {
                      return LatLng(e['lat'] ?? 0.0, e['lng'] ?? 0.0);
                    }).toList(),
                markers: <Marker>{},
                cameraTarget: const LatLng(0.0, 0.0),
                emotionEmoji: diaryEntry!['emotionEmoji'] ?? '',
              );

              final initialText = diaryEntry?['text'] ?? '';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) {
                  final diaryEntryObj = DiaryEntry(
                    date: widget.date,
                    text: initialText,
                    tags: [],
                    photos: [],
                    latitude: 0.0,
                    longitude: 0.0,
                    timeline: [],
                    markers: {},
                    cameraTarget: const LatLng(0, 0),
                    emotionEmoji: diaryEntry?['emotionEmoji'] ?? '',
                  );
                  return DiaryPage(
                    entry: diaryEntryObj,
                    emotionEmoji: diaryEntry?['emotionEmoji'] ?? '',
                    date: widget.date,
                  );
                },
                ),
              );
            }
          },
        ),
      ],
      child:
          diaryEntry == null
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "🗓 ${DateFormat('yyyy-MM-dd').format(DateTime.parse(widget.date))}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "오늘의 기분: ${diaryEntry!['emotionEmoji'] ?? 'No emotion'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text("🗺 Map"),
                          selected: true,
                          onSelected: (_) {},
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text("📷 Photos"),
                          selected: false,
                          onSelected: (_) {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildMapTimeline(),
                    const SizedBox(height: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "📝 다이어리 내용",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            diaryEntry?['final_text'] ?? 'No content available',
                            style: const TextStyle(fontSize: 15, height: 1.5),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "🏷 태그",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children:
                              (diaryEntry?['tags'] as List<dynamic>?)
                                  ?.map<Widget>(
                                    (tag) => Chip(label: Text(tag.toString())),
                                  )
                                  .toList() ??
                              [const Text('No tags')],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }

  // 지도 표시용 위젯
  Widget _buildMapTimeline() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(target: cameraTarget, zoom: 13),
        markers: markers,
        polylines: {
          Polyline(
            polylineId: const PolylineId("timeline"),
            points: timelinePolyline,
            color: Colors.blue,
            width: 5,
          ),
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: false,
        onMapCreated: (GoogleMapController controller) {},
      ),
    );
  }
}
