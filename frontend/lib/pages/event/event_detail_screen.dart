import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // ✅ 날짜 포맷용 import
import '/gallery_bottom_sheet.dart';
import '/pages/write/emoji.dart'; // 감정 이모지 선택 다이얼로그

class EventDetailScreen extends StatefulWidget {
  final DateTime selectedDate;
  final String emotionEmoji;
  final String timelineItem;

  const EventDetailScreen({
    required this.selectedDate,
    required this.emotionEmoji,
    required this.timelineItem,
    super.key,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  String selectedEmoji = ''; // 이모지 저장 상태
  final TextEditingController memoController = TextEditingController();
  // final TextEditingController _dateController = TextEditingController();
  // final TextEditingController _startTimeController = TextEditingController();
  // final TextEditingController _titleController = TextEditingController();
  // final TextEditingController _keywordsController = TextEditingController();
  // final TextEditingController _emotionController = TextEditingController();

  Set<String> selectedKeywords = {};

  String get timelineTime =>
      widget.timelineItem
          .split(' - ')
          .first;

  String get timelineDescription {
    final parts = widget.timelineItem.split(' - ');
    return parts.length > 1 ? parts[1] : '';
  }

  final allKeywords = [
    '벚꽃',
    '봄',
    '피크닉',
    '강아지',
    '석촌호수',
    '러버덕',
    '+',
  ];

  void onSave() {
    final savedData = {
      'date': DateFormat('yyyy-MM-dd').format(widget.selectedDate),
      'time': timelineTime,
      'description': timelineDescription,
      'emoji': selectedEmoji,
      'memo': memoController.text.trim(),
      'keywords': selectedKeywords.toList(),
    };

    // 저장 로직 삽입 위치
    debugPrint('📦 저장된 데이터: $savedData');

    // TODO: 여기서 Firebase / SQLite / 파일 등으로 저장할 수 있음
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('데이터가 저장되었습니다!')),
    );

    Navigator.pop(context); // 저장 후 화면 닫기
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
            decoration: const InputDecoration(
              hintText: '예: 카페, 운동, 공부 등',
            ),
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
                    allKeywords.insert(
                        allKeywords.length - 1, newKeyword); // '+' 앞에 삽입
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
      _showAddKeywordDialog(); // 키워드 입력창 호출
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

  void onBigBoxPlusTapped() {
    debugPrint("📦 큰 사각형 + 버튼 클릭됨");

    showModalBottomSheet(
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
  }

  @override
  void initState() {
    super.initState();
    selectedEmoji = widget.emotionEmoji; // ✅ 추가 필요
  }

  @override
  void dispose() {
    // ✨ 꼭 컨트롤러 해제해줘!
    memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final squareSize = MediaQuery
        .of(context)
        .size
        .width * 0.4;

    // ✅ 날짜 포맷팅
    final formattedDate = DateFormat('yyyy.MM.dd EEEE').format(
        widget.selectedDate);
    final formattedTime = DateFormat('HH:mm').format(widget.selectedDate);

    Widget buildInteractiveBox() {
      return GestureDetector(
        onTap: onBigBoxPlusTapped,
        child: Container(
          width: squareSize,
          height: squareSize,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Center(
            child: Icon(Icons.add, size: 32),
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery
                    .of(context)
                    .viewInsets
                    .bottom + 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ✅ 동적으로 날짜 표시
                      Text(
                        formattedDate,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),

                      // ✅ 뒤로가기 및 완료 버튼
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context); // ✅ 뒤로가기 연결
                            },
                            icon: const Icon(Icons.arrow_back),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: onSave, // ✅ 저장 함수 연결
                            child: const Text("완료"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ✅ 타임라인 기반 시간 및 설명 표시
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(timelineTime,
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 12),
                              Icon(Icons.wb_sunny, color: Colors.orange),
                              // 날씨 아이콘은 향후 확장 가능
                            ],
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              timelineDescription,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ✅ 사각형 2개
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: [
                          buildInteractiveBox(),
                          buildInteractiveBox(),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ✅ 메모 입력 필드
                      TextField(
                        onChanged: (value) {
                          debugPrint("💬 메모 내용: $value");
                          // TODO: 메모 저장 로직이 있다면 여기에 추가
                        },
                        controller: memoController,
                        maxLines: 3,
                        keyboardType: TextInputType.text,
                        autofillHints: const <String>[],
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: '일정에 대한 메모를 입력하세요',
                          hintText: '예: 오늘 러버덕이 귀여웠다!',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                        ),
                      ),

                      // ✅ 키워드 말풍선
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: allKeywords.map((keyword) {
                          final isPlus = keyword == '+';
                          final isSelected = selectedKeywords.contains(keyword);

                          return ChoiceChip(
                            label: Text(keyword),
                            selected: isSelected,
                            selectedColor: isPlus
                                ? Colors.grey.shade300
                                : Colors.blue.shade300,
                            backgroundColor: Colors.grey.shade300,
                            labelStyle: TextStyle(
                              color: isSelected || isPlus
                                  ? Colors.black
                                  : Colors.black,
                            ),
                            onSelected: (_) => toggleKeyword(keyword),
                          );
                        }).toList(),
                      ),

                      // const Spacer(),
                      const SizedBox(height: 200),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text("나의 마음", style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),

                          // 선택된 이모지 표시
                          if (selectedEmoji.isNotEmpty)
                            Text(
                              selectedEmoji ?? '😀', // null이면 기본값 표시
                              style: const TextStyle(fontSize: 20),
                            ),

                          IconButton(
                            onPressed: () async {
                              final result = await showEventEmotionDialog(
                                  context); // ✅ 여기만 바꾸면 돼!
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