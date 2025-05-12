import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '/gallery_bottom_sheet.dart';
import '/pages/write/emoji.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:test_sheep/constants/location_data.dart';
import '../../theme/templates.dart';
import '../../theme/themed_scaffold.dart';

class EventDetailScreen extends StatefulWidget {
  final DateTime selectedDate;
  final String emotionEmoji;
  final String timelineItem;
  final LatLng selectedLatLng;
  final String location;

  const EventDetailScreen({
    required this.selectedDate,
    required this.emotionEmoji,
    required this.timelineItem,
    required this.selectedLatLng,
    required this.location,
    super.key,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  String selectedEmoji = '';
  List<String?> imageSlots = [null, null]; // 두 개의 슬롯
  final TextEditingController memoController = TextEditingController();
  Set<String> selectedKeywords = {};

  String get timelineTime => widget.timelineItem.split(' - ').first;

  String get timelineDescription {
    final parts = widget.timelineItem.split(' - ');
    return parts.length > 1 ? parts[1] : '';
  }

  final allKeywords = ['벚꽃', '봄', '피크닉', '강아지', '석촌호수', '러버덕', '+'];

  @override
  void initState() {
    super.initState();
    selectedEmoji = widget.emotionEmoji;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final images = locationImages[widget.location] ?? [];

      setState(() {
        if (imageSlots[0] == null && images.isNotEmpty) {
          imageSlots[0] = images[0];
        }
        if (imageSlots[1] == null && images.length > 1) {
          imageSlots[1] = images[1];
        }
      });
    });
  }

  @override
  void dispose() {
    memoController.dispose();
    super.dispose();
  }

  Future<void> sendEventToApi({
    required String title,
    required double longitude,
    required double latitude,
    required String time,
    required String emotion,
    required String memos,
    required List<String> keywords,
  }) async {
    final url = Uri.parse('http://10.0.2.2:8000/api/events/');
    final body = jsonEncode({
      "title": title,
      "longitude": longitude,
      "latitude": latitude,
      "start_time": time,
      "emotion": emotion,
      "memos": memos,
      "keywords": keywords,
    });

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      debugPrint('✅ 이벤트 저장 성공!');
    } else {
      debugPrint('❌ 이벤트 저장 실패: ${response.statusCode} ${response.body}');
      throw Exception('이벤트 저장 실패');
    }
  }

  void onSave() async {
    final int emotionId = convertEmojiToId(selectedEmoji);

    final savedData = {
      'title': timelineDescription,
      'longitude': widget.selectedLatLng.longitude,
      'latitude': widget.selectedLatLng.latitude,
      'time': timelineTime,
      'emotion': emotionId, // 숫자 ID로 변환해서 저장/전송!
      'memos': memoController.text.trim(),
      'keywords': selectedKeywords.toList(),
    };

    try {
      await sendEventToApi(
        title: savedData['title'] as String,
        longitude: savedData['longitude'] as double,
        latitude: savedData['latitude'] as double,
        time: savedData['time'] as String,
        emotion: savedData['emotion'].toString(),
        memos: savedData['memos'] as String,
        keywords: List<String>.from(savedData['keywords'] as List),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('데이터가 저장되었습니다!')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    }
  }

  Future<void> _showAddKeywordDialog() async {
    String newKeyword = '';

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('새 키워드 추가'),
          content: TextField(
            autofocus: true,
            onChanged: (value) {
              newKeyword = value.trim();
            },
            decoration: const InputDecoration(hintText: '예: 카페, 운동, 공부 등'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                if (newKeyword.isNotEmpty) {
                  setState(() {
                    allKeywords.insert(allKeywords.length - 1, newKeyword);
                    selectedKeywords.add(newKeyword);
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );
  }

  void toggleKeyword(String keyword) {
    if (keyword == '+') {
      _showAddKeywordDialog();
      return;
    }

    setState(() {
      if (selectedKeywords.contains(keyword)) {
        selectedKeywords.remove(keyword);
      } else {
        selectedKeywords.add(keyword);
      }
    });
  }

  void onBigBoxPlusTapped() async {
    debugPrint("📦 큰 사각형 + 버튼 클릭됨");

    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return const GalleryBottomSheet();
      },
    );

    // 이미지 두 장 선택된 경우에만 상태 저장
    if (result != null && result.length == 2) {
      setState(() {
        imageSlots[0] = result[0]; // 첫 번째 이미지
        imageSlots[1] = result[1]; // 두 번째 이미지
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final squareSize = MediaQuery.of(context).size.width * 0.4;

    final formattedDate = DateFormat(
      'yyyy.MM.dd EEEE',
    ).format(widget.selectedDate);
    final formattedTime = DateFormat('HH:mm').format(widget.selectedDate);
    // final images = locationImages[widget.location] ?? [];
    final images = locationImages[widget.location] ?? [];

    // 디버깅 로그 출력
    print('location: ${widget.location}');
    print('images: $images');

    if (imageSlots[0] == null && images.isNotEmpty) {
      imageSlots[0] = images.first;
    }

    Widget buildInteractiveBox(int index) {
      return GestureDetector(
        onTap: () async {
          final result = await showModalBottomSheet<List<String>>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) => const GalleryBottomSheet(),
          );

          if (result != null && result.isNotEmpty) {
            setState(() {
              if (result.length == 2) {
                // 두 개를 동시에 업데이트
                imageSlots[0] = result[0];
                imageSlots[1] = result[1];
              } else {
                // 한 개만 선택된 경우 해당 인덱스만 업데이트
                imageSlots[index] = result.first;
              }
            });
          }
        },
        child: Container(
          width: squareSize,
          height: squareSize,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            image:
                imageSlots[index] != null
                    ? DecorationImage(
                      image: AssetImage(imageSlots[index]!),
                      fit: BoxFit.cover,
                    )
                    : null,
          ),
          child:
              imageSlots[index] == null
                  ? const Center(child: Icon(Icons.add, size: 32))
                  : null,
        ),
      );
    }

    return ThemedScaffold(
      title: formattedDate,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        TextButton(
          onPressed: onSave,
          child: const Text("완료", style: TextStyle(color: Colors.white)),
        ),
      ],
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(timelineTime, style: const TextStyle(fontSize: 16)), // ← 여기!!
                          const SizedBox(width: 12),
                          const Icon(Icons.wb_sunny, color: Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          timelineDescription,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: List.generate(2, (index) => buildInteractiveBox(index)),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        onChanged: (value) => debugPrint("💬 메모 내용: $value"),
                        controller: memoController,
                        maxLines: 3,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: '일정에 대한 메모를 입력하세요',
                          hintText: '예: 오늘 러버덕이 귀여웠다!',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding:
                          const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children:
                            allKeywords.map((keyword) {
                              final isPlus = keyword == '+';
                              final isSelected = selectedKeywords.contains(
                                keyword,
                              );

                              return ChoiceChip(
                                label: Text(keyword),
                                selected: isSelected,
                                selectedColor:
                                    isPlus
                                        ? Colors.grey.shade300
                                        : Colors.blue.shade300,
                                backgroundColor: Colors.grey.shade300,
                                labelStyle: TextStyle(
                                  color:
                                      isSelected || isPlus
                                          ? Colors.black
                                          : Colors.black,
                                ),
                                onSelected: (_) => toggleKeyword(keyword),
                              );
                            }).toList(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text("나의 마음", style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          if (selectedEmoji.isNotEmpty)
                            Text(
                              selectedEmoji ?? '😀',
                              style: const TextStyle(fontSize: 20),
                            ),
                          IconButton(
                            onPressed: () async {
                              final result = await showEventEmotionDialog(
                                context,
                              );
                              if (result != null && result is String) {
                                setState(() {
                                  selectedEmoji = result;
                                });
                              }
                            },
                            icon: const Icon(Icons.emoji_emotions),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
