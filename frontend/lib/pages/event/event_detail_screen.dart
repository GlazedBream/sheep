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
import 'package:image_picker/image_picker.dart';
import '../../services/upload_service.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class EventDetailScreen extends StatefulWidget {
  final DateTime selectedDate;
  final String emotionEmoji;
  final String timelineItem;
  final LatLng selectedLatLng;
  final String location;
  final int index;
  final int? eventId; // 기존 이벤트 ID (수정 시 사용)

  const EventDetailScreen({
    required this.selectedDate,
    required this.emotionEmoji,
    required this.timelineItem,
    required this.selectedLatLng,
    required this.location,
    required this.index,
    this.eventId, // 수정 시에만 전달
    super.key,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  String selectedEmoji = '';
  String memo = "";
  String photoUrl = "";
  int? eventId; // 이벤트 ID (수정 시 사용)


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
    
    // 이벤트 ID가 있으면 기존 데이터 로드
    if (widget.eventId != null) {
      _loadEventDetails();
    }

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

  // S3에 업로드할 이미지들의 원본 경로와 S3 키를 매핑하는 맵
  final Map<String, String> _imagePathToS3Key = {};

  // 에셋 이미지에서 키워드 추출
  Future<void> extractKeywordFromAssetImage(String imagePath) async {
    try {
      final file = await ImageKeywordExtractor.assetToFile(imagePath);
      final result = await ImageKeywordExtractor().extract(file);
      
      if (result != null) {
        setState(() {
          // 중복 키워드 제거하고 추가
          final newKeywords = result.keywordsKo.where((keyword) => 
            !selectedKeywords.contains(keyword)
          ).toList();
          
          selectedKeywords.addAll(newKeywords);
          allKeywords.addAll(newKeywords);
        });
      }
    } catch (e) {
      print('키워드 추출 중 오류: $e');
    }
  }

  Future<void> uploadImagesAndReplaceSlots() async {
    _imagePathToS3Key.clear(); // 맵 초기화
    
    for (int i = 0; i < imageSlots.length; i++) {
      final imagePath = imageSlots[i];
      if (imagePath == null || !imagePath.startsWith('assets/')) continue;

      // asset 이미지 → ByteData 로딩 후 temp 디렉토리에 저장
      final byteData = await rootBundle.load(imagePath);
      final tempDir = await getTemporaryDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imagePath.split('/').last}';
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());

      // S3에 업로드 및 Picture 모델에 임시 레코드 생성
      final uploadResult = await UploadService.uploadImage(tempFile);
      if (uploadResult != null && uploadResult['s3_key'] != null) {
        final s3Key = uploadResult['s3_key'] as String;
        final pictureId = uploadResult['picture_id'] as int;
        final status = uploadResult['status'] as String;
        
        print('이미지 업로드 성공 - S3 Key: $s3Key, Picture ID: $pictureId, Status: $status');
        _imagePathToS3Key[imagePath] = s3Key; // 원본 경로와 S3 키 매핑 저장
      } else {
        print('이미지 업로드 실패: $imagePath');
      }
    }
  }


  // 공통 요청 바디 생성
  Map<String, dynamic> _createEventRequestBody({
    required String title,
    required double longitude,
    required double latitude,
    required String time,
    required String emotion,
    required String memos,
    required List<String> keywords,
  }) {
    // 이미지 처리: 원본 경로는 유지하면서 필요한 경우 S3 키로 변환
    final List<Map<String, dynamic>> imageData = [];
    
    for (final imagePath in imageSlots) {
      if (imagePath == null) continue;
      
      if (imagePath.startsWith('assets/')) {
        // 에셋 이미지인 경우 S3 키로 변환
        final s3Key = _imagePathToS3Key[imagePath];
        if (s3Key != null) {
          // 여기서는 간단히 s3_key만 포함시킵니다.
          // 실제로는 UploadService.uploadImage()에서 반환된 picture_id도 함께 전달할 수 있습니다.
          imageData.add({
            'original_path': imagePath,
            's3_key': s3Key,
            // 'picture_id': pictureId, // 필요시 추가
          });
        }
      } else {
        // 이미 S3 키인 경우 (기존 처리 유지)
        imageData.add({
          'original_path': imagePath,
          's3_key': imagePath,
        });
      }
    }

    return {
      "date": widget.selectedDate.toIso8601String().split('T')[0],
      "time": time,
      "title": title,
      "longitude": longitude,
      "latitude": latitude,
      "images": imageData.map((img) => img['s3_key']).toList(),
      "image_data": imageData,
      "emotion_id": int.parse(emotion),
      "weather": "sunny",
      "memo_content": memos,  // 최상위 레벨에 memo_content 추가
      "memos": [
        {"memo_content": memos},  // 하위 호환성을 위해 유지
      ],
      "keywords":
          keywords
              .map(
                (keyword) => {"content": keyword, "source_type": "user_input"},
              )
              .toList(),
    };
  }

  // 이벤트 생성 API 호출
  Future<int?> _createEvent({
    required Map<String, dynamic> requestBody,
  }) async {
    final url = Uri.parse('http://10.0.2.2:8000/api/events/create/');
    final headers = await getAuthHeaders();
    final body = jsonEncode(requestBody);

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      debugPrint('✅ 이벤트 생성 성공!');
      final responseData = jsonDecode(response.body);
      return responseData['event_id'];
    } else {
      debugPrint('❌ 이벤트 생성 실패: ${response.statusCode} ${response.body}');
      return null;
    }
  }

  // 이벤트 수정 API 호출
  Future<int?> _updateEvent({
    required int eventId,
    required Map<String, dynamic> requestBody,
  }) async {
    final url = Uri.parse('http://10.0.2.2:8000/api/events/$eventId/');
    final headers = await getAuthHeaders();
    headers['Content-Type'] = 'application/json';
    
    final body = jsonEncode(requestBody);
    final response = await http.put(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      debugPrint('✅ 이벤트 수정 성공!');
      return eventId; // 수정된 이벤트 ID 반환
    } else {
      debugPrint('❌ 이벤트 수정 실패: ${response.statusCode} ${response.body}');
      return null;
    }
  }

  // 이벤트 생성 또는 수정
  Future<int?> sendEventToApi({
    required String title,
    required double longitude,
    required double latitude,
    required String time,
    required String emotion,
    required String memos,
    required List<String> keywords,
    int? eventId, // 수정 시에만 전달
  }) async {
    // 요청 바디 생성
    final requestBody = _createEventRequestBody(
      title: title,
      longitude: longitude,
      latitude: latitude,
      time: time,
      emotion: emotion,
      memos: memos,
      keywords: keywords,
    );

    // 이벤트 ID가 있으면 수정, 없으면 생성
    if (eventId != null) {
      return await _updateEvent(eventId: eventId, requestBody: requestBody);
    } else {
      return await _createEvent(requestBody: requestBody);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('시간 파싱 실패: $e')),
      );
      return;
    }

    final savedData = {
      'title': timelineDescription,
      'longitude': widget.selectedLatLng.longitude,
      'latitude': widget.selectedLatLng.latitude,
      'time': formattedTime,
      'emotion': emotionId,
      'memos': memoController.text.trim().isNotEmpty
          ? memoController.text.trim()
          : '기록 없음',
      'keywords': selectedKeywords.toList(),
    };

    try {
      // 이미지 업로드
      await uploadImagesAndReplaceSlots();

      // 로컬 저장소에 저장
      await _saveEventDetailsLocally();

      // 이벤트 생성 또는 수정
      final int? event_id = await sendEventToApi(
        title: savedData['title'] as String,
        longitude: savedData['longitude'] as double,
        latitude: savedData['latitude'] as double,
        time: savedData['time'] as String,
        emotion: savedData['emotion'].toString(),
        memos: savedData['memos'] as String,
        keywords: List<String>.from(savedData['keywords'] as List),
        eventId: widget.eventId, // 수정 시에만 값이 있음
      );

      // ❗ Navigator 사용 전에도 mounted 체크
      if (!mounted) return;

      if (event_id != null) {
        debugPrint('✅ 이벤트 저장/수정 성공: $event_id');
        Navigator.pop(context, event_id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이벤트 저장은 성공했지만 ID를 받아오지 못했습니다.')),
        );
        throw Exception('이벤트 저장/수정에 실패했습니다.');
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
      final imagePath = result[0];
      if (imagePath.startsWith('assets/')) {
        // 에셋 이미지인 경우
        await extractKeywordFromAssetImage(imagePath);
      } else {
        // 파일 경로인 경우
        try {
          final extractor = ImageKeywordExtractor();
          final imageFile = File(imagePath);
          final keywordResult = await extractor.extract(imageFile);
          
          if (keywordResult != null) {
            setState(() {
              selectedKeywords.addAll(keywordResult.keywordsKo);
              allKeywords = [...keywordResult.keywordsKo, '+'];
            });
          }
        } catch (e) {
          print('이미지에서 키워드 추출 중 오류: $e');
        }
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
