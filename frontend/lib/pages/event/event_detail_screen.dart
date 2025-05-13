import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '/gallery_bottom_sheet.dart';
import '/pages/write/emoji.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:test_sheep/constants/location_data.dart';
import '/models/image_keyword.dart'; // ImageKeywordExtractor를 여기서 import
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '/helpers/auth_helper.dart';

class EventDetailScreen extends StatefulWidget {
  final DateTime selectedDate;
  final String emotionEmoji;
  final String timelineItem;
  final LatLng selectedLatLng;
  final String location;
  final int index;

  const EventDetailScreen({
    required this.selectedDate,
    required this.emotionEmoji,
    required this.timelineItem,
    required this.selectedLatLng,
    required this.location,
    required this.index,
    super.key,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  String selectedEmoji = '';
  String memo = "";
  String photoUrl = "";

  List<String?> imageSlots = [null, null]; // 두 개의 슬롯
  final TextEditingController memoController = TextEditingController();
  // Set<String> selectedKeywords = {};
  List<String> selectedKeywords = []; // ✅ 이건 괜찮아

  String get timelineTime => widget.timelineItem.split(' - ').first;

  String get timelineDescription {
    final parts = widget.timelineItem.split(' - ');
    return parts.length > 1 ? parts[1] : '';
  }

  List<String> allKeywords = []; // 초기엔 빈 리스트

  @override
  void initState() {
    super.initState();
    selectedEmoji = widget.emotionEmoji;
    _loadEventDetails();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final images = locationImages[widget.location] ?? [];

      setState(() {
        if (imageSlots[0] == null && images.isNotEmpty) {
          imageSlots[0] = images[0];
        }
        if (imageSlots[1] == null && images.length > 1) {
          imageSlots[1] = images[1];
        }
      });

      // ✅ asset 이미지가 존재하면 키워드 자동 추출
      // if (images.isNotEmpty) {
      //   await extractKeywordFromAssetImage(images[0]);
      for (final image in images.take(2)) {
        await extractKeywordFromAssetImage(image);
      }
    });
  }

  @override
  void dispose() {
    memoController.dispose();
    super.dispose();
  }

  Future<int?> sendEventToApi({
    required String title,
    required double longitude,
    required double latitude,
    required String time,
    required String emotion,
    required String memos,
    required List<String> keywords,
  }) async {
    final url = Uri.parse('http://10.0.2.2:8000/api/events/create/');

    // 이미지 처리
    final images =
        imageSlots
            .where((image) => image != null)
            .map((image) => image!)
            .toList();

    final body = jsonEncode({
      "date": widget.selectedDate.toIso8601String().split('T')[0],
      "time": time,
      "title": title,
      "longitude": longitude,
      "latitude": latitude,
      "images": images,
      "emotion_id": int.parse(emotion),
      "weather": "sunny",
      "memos": [
        {"content": memos},
      ],
      "keywords":
          keywords
              .map(
                (keyword) => {"content": keyword, "source_type": "user_input"},
              )
              .toList(),
    });

    final headers = await getAuthHeaders();

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      debugPrint('✅ 이벤트 저장 성공!');
      final responseData = jsonDecode(response.body);
      return responseData['event_id']; // <- 서버 응답에 event_id 포함되어 있어야 함
    } else {
      debugPrint('❌ 이벤트 저장 실패: ${response.statusCode} ${response.body}');
      return null;
    }
  }

  void onSave() async {
    final int emotionId = convertEmojiToId(selectedEmoji);
    final String rawTime = widget.timelineItem.split(' - ').first.trim();

    final now = DateTime.now();
    final String fullRawTime =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}T$rawTime';

    String formattedTime;
    try {
      final DateFormat format = DateFormat('yyyy-MM-ddTHH:mm');
      final DateTime parsedTime = format.parse(fullRawTime);

      final String timezoneOffset = '+09:00';
      formattedTime = parsedTime.toIso8601String().replaceFirst(
        'Z',
        timezoneOffset,
      );
    } catch (e) {
      // ❗ 여기도 context 사용 전에 mounted 체크
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('시간 파싱 실패: $e')));
      return;
    }

    final savedData = {
      'title': timelineDescription,
      'longitude': widget.selectedLatLng.longitude,
      'latitude': widget.selectedLatLng.latitude,
      'time': formattedTime,
      'emotion': emotionId,
      'memos':
          memoController.text.trim().isNotEmpty
              ? memoController.text.trim()
              : '기록 없음',
      'keywords': selectedKeywords.toList(),
    };

    try {
      await _saveEventDetailsLocally();

      final int? event_id = await sendEventToApi(
        title: savedData['title'] as String,
        longitude: savedData['longitude'] as double,
        latitude: savedData['latitude'] as double,
        time: savedData['time'] as String,
        emotion: savedData['emotion'].toString(),
        memos: savedData['memos'] as String,
        keywords: List<String>.from(savedData['keywords'] as List),
      );

      // ❗ Navigator 사용 전에도 mounted 체크
      if (!mounted) return;

      if (event_id != null) {
        print(event_id);
        Navigator.pop(context, event_id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이벤트 저장은 성공했지만 ID를 받아오지 못했습니다.')),
        );
      }
    } catch (e) {
      // ❗ 예외 처리 시 context 사용 전에도 체크
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    }
  }

  // ✅ 로컬 저장 함수
  Future<void> _saveEventDetailsLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final eventData = jsonEncode({
      'memo': memoController.text.trim(),
      'imageSlots': imageSlots,
      'selectedKeywords': selectedKeywords.toList(),
      'selectedEmoji': selectedEmoji,
    });
    await prefs.setString('event_${widget.index}', eventData);
  }

  // ✅ 로컬 불러오기 함수 (호출은 따로 필요 시 사용)
  Future<void> _loadEventDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('event_${widget.index}');
    if (data != null) {
      final decoded = jsonDecode(data);
      setState(() {
        memoController.text = decoded['memo'] ?? '';
        imageSlots = List<String?>.from(decoded['imageSlots'] ?? [null, null]);
        // selectedKeywords = Set<String>.from(decoded['selectedKeywords'] ?? []);
        selectedKeywords =
            (decoded['selectedKeywords'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toSet()
                .toList() ??
            [];
        selectedEmoji = decoded['selectedEmoji'] ?? '';
      });
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

  // Future<void> extractKeywordFromAssetImage(String assetImagePath) async {
  //   final extractor = ImageKeywordExtractor();
  //   final imageFile = await ImageKeywordExtractor.assetToFile(assetImagePath);
  //   final keywordResult = await extractor.extract(imageFile);
  //
  //   if (!mounted) return; // 🔒 위젯이 아직 살아 있는지 확인
  //
  //   if (keywordResult != null) {
  //     setState(() {
  //       allKeywords = [...keywordResult.keywordsKo, '+'];
  //       selectedKeywords.addAll(keywordResult.keywordsKo);
  //     });
  //   }
  // }

  Future<void> extractKeywordFromAssetImage(String assetImagePath) async {
    final extractor = ImageKeywordExtractor();
    final imageFile = await ImageKeywordExtractor.assetToFile(assetImagePath);
    final keywordResult = await extractor.extract(imageFile);

    if (!mounted) return;

    if (keywordResult != null) {
      setState(() {
        // ✅ 중복 없는 키워드 누적
        allKeywords = {...allKeywords, ...keywordResult.keywordsKo}.toList();

        selectedKeywords =
            (selectedKeywords.toSet()..addAll(keywordResult.keywordsKo))
                .toList();

        // ✅ "+" 기호가 항상 마지막에 오도록 정렬
        allKeywords.remove('+');
        allKeywords.add('+');
      });
    }
  }

  void onBigBoxPlusTapped() async {
    print("✅ 이미지 키워드 추출 시작됨!");
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

    // 이미지가 선택된 경우에만 상태 저장
    if (result != null && result.isNotEmpty) {
      setState(() {
        // 이미지 선택 후 상태 저장
        if (result.length == 2) {
          imageSlots[0] = result[0]; // 첫 번째 이미지
          imageSlots[1] = result[1]; // 두 번째 이미지
        } else {
          imageSlots[0] = result[0]; // 하나만 선택된 경우
        }
      });

      // 첫 번째 이미지에서 키워드 추출
      final imageFile = File(result[0]); // 이미지 파일을 File로 변환
      final extractor =
          ImageKeywordExtractor(); // ImageKeywordExtractor 인스턴스 생성
      final keywordResult = await extractor.extract(imageFile); // 키워드 추출
      print('추출된 키워드: ${keywordResult?.keywordsKo}');

      // 추출된 키워드가 있을 경우
      if (keywordResult != null) {
        setState(() {
          selectedKeywords.addAll(keywordResult.keywordsKo);

          // 여기서 allKeywords도 업데이트
          allKeywords = [...keywordResult.keywordsKo, '+']; // 한국어 키워드 추가
        });
      }
    }
  }

  bool _hasChanges() {
    return memoController.text.isNotEmpty ||
        selectedEmoji.isNotEmpty ||
        selectedKeywords.isNotEmpty;
  }

  Future<bool> _onWillPop() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('event_${widget.index}');

    final currentData = jsonEncode({
      'memo': memoController.text.trim(),
      'imageSlots': imageSlots,
      'selectedKeywords': selectedKeywords.toList(),
      'selectedEmoji': selectedEmoji,
    });

    // 변경사항이 없으면 그냥 나가기 허용
    if (!_hasChanges()) {
      return true;
    }

    // 저장한 적이 없거나, 저장된 값과 현재 값이 다르면 팝업
    if (savedData == null || savedData != currentData) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('변경 사항이 저장되지 않았습니다'),
              content: const Text('저장하지 않고 나가시겠습니까?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('나가기'),
                ),
              ],
            ),
      );
      return shouldExit ?? false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final squareSize = MediaQuery.of(context).size.width * 0.4;

    final formattedDate = DateFormat(
      'yyyy.MM.dd EEEE',
    ).format(widget.selectedDate);
    final formattedTime = DateFormat('HH:mm').format(widget.selectedDate);
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

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
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
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () async {
                                final shouldLeave = await _onWillPop();
                                if (shouldLeave) {
                                  Navigator.of(context).pop();
                                }
                              },
                              icon: const Icon(Icons.arrow_back),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: onSave,
                              child: const Text("완료"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  timelineTime,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 12),
                                Icon(Icons.wb_sunny, color: Colors.orange),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                timelineDescription,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: List.generate(
                            2,
                            (index) => buildInteractiveBox(index),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          onChanged: (value) {
                            debugPrint("💬 메모 내용: $value");
                          },
                          controller: memoController,
                          maxLines: 3,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            labelText: '일정에 대한 메모를 입력하세요',
                            hintText: '예: 오늘 러버덕이 귀여웠다!',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                          ),
                        ),
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
      ),
    );
  }
}
