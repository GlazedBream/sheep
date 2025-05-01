import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/diary_data.dart';
import '../write/diary_page.dart';
import 'package:provider/provider.dart';
import '../../data/diary_provider.dart'; // 경로는 실제 위치에 맞게 조정
import '../../data/diary.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class ReviewPage extends StatefulWidget {
  final DiaryEntry entry;

  const ReviewPage({super.key, required this.entry});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  bool showMap = true;
  int _selectedIndex = 1; // ✅ Calendar 탭이 중심이라고 가정 (0: Home, 1: Calendar, 2: Profile)

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // 👉 실제로는 아래에 각 화면으로 이동하는 로직 추가 필요
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/calendar');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📖 Diary Review"),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "🗓 ${widget.entry.date}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("🗺 Map"),
                  selected: showMap,
                  onSelected: (_) => setState(() => showMap = true),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("📷 Photos"),
                  selected: !showMap,
                  onSelected: (_) => setState(() => showMap = false),
                ),
              ],
            ),
            const SizedBox(height: 16),

            showMap
                ? _buildMapTimeline()
                : _buildPhotoSlider(),

            const SizedBox(height: 24),

            const Text("📝 다이어리 내용", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.entry.text,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),

            const Text("🏷 태그", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: widget.entry.tags.map((tag) => Chip(label: Text(tag))).toList(),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 150), // 원하는 만큼 높이 조절
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DiaryPage(
                          entry: widget.entry,  // DiaryEntry 객체를 전달
                          emotionEmoji: widget.entry.emotionEmoji,  // DiaryEntry에서 emotionEmoji 전달
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapTimeline() {
    return Container(
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
    );
  }

  Widget _buildPhotoSlider() {
    if (widget.entry.photos.isEmpty) {
      return const Text("No photos available.");
    }

    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: widget.entry.photos.length,
        itemBuilder: (context, index) {
          final photoUrl = widget.entry.photos[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                photoUrl,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}