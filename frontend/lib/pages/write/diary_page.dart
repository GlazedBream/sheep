import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/diary.dart';
import '../../data/diary_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DiaryEntry {
  final String date;
  final String text;
  final List<String> tags;
  final List<String> photos;

  DiaryEntry({
    required this.date,
    required this.text,
    required this.tags,
    required this.photos,
  });
}

extension DiaryEntryExtension on DiaryEntry {
  Diary toDiary() {
    return Diary(
      id: UniqueKey().toString(),
      date: date,
      text: text,
      tags: tags,
      photos: photos,
    );
  }
}

class DiaryPage extends StatefulWidget {
  final DiaryEntry entry;

  const DiaryPage({super.key, required this.entry});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  final TextEditingController _textController = TextEditingController();
  bool showMap = true;
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _textController.text = widget.entry.text;
  }

  void _saveDiary() {
    final updatedDiary = Diary(
      id: UniqueKey().toString(),
      date: widget.entry.date,
      text: _textController.text,
      tags: widget.entry.tags,
      photos: widget.entry.photos,
    );

    Provider.of<DiaryProvider>(context, listen: false).addDiary(updatedDiary);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write Diary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveDiary,
          ),
        ],
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜
            Text(
              "🗓 ${widget.entry.date}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // 지도/사진 전환 ChoiceChip
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

            // 지도/사진 영역
            showMap ? _buildMapTimeline() : _buildPhotoSlider(),
            const SizedBox(height: 24),

            // 다이어리 내용 입력
            const Text("📝 다이어리 내용", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLines: null,
              decoration: InputDecoration(
                hintText: '오늘의 기록을 입력하세요...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(12),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 24),

            // 태그
            if (widget.entry.tags.isNotEmpty) ...[
              const Text("🏷 태그", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: widget.entry.tags.map((tag) => Chip(label: Text(tag))).toList(),
              ),
            ],

            // 사진 (optional, 사진 탭에서만 보여주고 싶으면 이 부분은 생략 가능)
            // if (widget.entry.photos.isNotEmpty && !showMap) ...[
            //   const SizedBox(height: 24),
            //   const Text("📷 사진", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            //   const SizedBox(height: 8),
            //   _buildPhotoSlider(),
            // ],
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