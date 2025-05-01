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
  final double latitude; // 위도
  final double longitude; // 경도
  final List<LatLng> timeline; // 타임라인 좌표들
  final Set<Marker> markers; // 지도 마커들
  final LatLng cameraTarget; // 지도 중심 좌표
  final String emotionEmoji; // 🥳 선택된 이모지

  DiaryEntry({
    required this.date,
    required this.text,
    required this.tags,
    required this.photos,
    required this.latitude,
    required this.longitude,
    required this.timeline,
    required this.markers,
    required this.cameraTarget,
    required this.emotionEmoji,
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
      longitude: longitude,
      latitude: latitude,

      timeline: timeline
          .map((latLng) => {'lat': latLng.latitude, 'lng': latLng.longitude})
          .toList(),
      markers: markers.map((marker) => {
        'id': marker.markerId.value,
        'lat': marker.position.latitude,
        'lng': marker.position.longitude,
      }).toList(),
      cameraTarget: {
        'lat': cameraTarget.latitude,
        'lng': cameraTarget.longitude,
      },

      emotionEmoji: emotionEmoji,

    );
  }
}

class DiaryPage extends StatefulWidget {
  final DiaryEntry entry;
  final String emotionEmoji;

  const DiaryPage({
    super.key,
    required this.entry,  // DiaryEntry 객체 전달
    required this.emotionEmoji,  // 이모지 전달
  });

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
    final updatedEntry = DiaryEntry(
      date: widget.entry.date,
      text: _textController.text,
      tags: widget.entry.tags,
      photos: widget.entry.photos,
      latitude: widget.entry.latitude,
      longitude: widget.entry.longitude,
      timeline: widget.entry.timeline,
      cameraTarget: widget.entry.cameraTarget,
      markers: widget.entry.markers,
      emotionEmoji: widget.entry.emotionEmoji, // 이모지 저장
    );

    final updatedDiary = updatedEntry.toDiary();

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
            Row(
              children: [
                Text(
                  "🗓 ${widget.entry.date}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 130),
                if (widget.entry.emotionEmoji.isNotEmpty) ...[
                  const Text(
                    "오늘의 기분 ",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    widget.entry.emotionEmoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ],
              ],
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
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.entry.cameraTarget,
          zoom: 12,
        ),
        markers: widget.entry.markers,
        polylines: {
          if (widget.entry.timeline.length > 1)
            Polyline(
              polylineId: PolylineId("timelinePath"),
              color: Colors.blueAccent,
              width: 4,
              points: widget.entry.timeline,
            ),
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: false,
        onMapCreated: (controller) {},
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