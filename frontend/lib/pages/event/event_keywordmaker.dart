import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/templates.dart';
import '../../theme/themed_scaffold.dart';

class event_keywordmaker extends StatelessWidget {
  const event_keywordmaker({super.key});

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).scaffoldBackgroundColor;
    final squareSize = MediaQuery.of(context).size.width * 0.4;

    Widget buildSquare({required bool isWhite}) {
      return GestureDetector(
        onTap: () {
          if (isWhite) {
            // + 버튼 눌렀을 때 액션
            print("정사각형 + 버튼 클릭됨");
          }
        },
        child: Container(
          width: squareSize,
          height: squareSize,
          decoration: BoxDecoration(
            color: isWhite ? Colors.white : baseColor,
            borderRadius: BorderRadius.circular(8),
            border: isWhite ? Border.all(color: Colors.grey.shade300) : null,
          ),
          child: isWhite
              ? const Center(child: Icon(Icons.add))
              : const SizedBox.shrink(),
        ),
      );
    }

    return ThemedScaffold(
      title: '',
      child: SafeArea(
        child: Column(
          children: [
            // 1~3시: 뒤로가기, 완료
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: const Text("완료"),
                  ),
                ],
              ),
            ),

            // 4~6시: 날짜, 날씨, 위치
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Column(
                children: [
                  Text("12:30", style: TextStyle(fontSize: 18)),
                  Text("맑음", style: TextStyle(fontSize: 16)),
                  Text("노량진동", style: TextStyle(fontSize: 16)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 7~12시: 2x2 사각형
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  buildSquare(isWhite: true),
                  buildSquare(isWhite: true),
                  buildSquare(isWhite: false),
                  buildSquare(isWhite: false),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 13~18시: 메모추가 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    print("메모 추가 클릭됨");
                  },
                  child: const Text("메모 추가", style: TextStyle(fontSize: 18)),
                ),
              ),
            ),

            // 키워드 텍스트
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text("키워드를 추가해주세요", style: TextStyle(fontSize: 16)),
            ),

            // 19~21시: 키워드 말풍선 버튼들
            Wrap(
              spacing: 12,
              children: [
                ActionChip(
                  label: const Text("헬스장"),
                  onPressed: () {
                    print("헬스장 클릭됨");
                  },
                ),
                ActionChip(
                  label: const Text("프로틴"),
                  onPressed: () {
                    print("프로틴 클릭됨");
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.add),
                  label: const Text(""),
                  backgroundColor: Colors.grey.shade200,
                  onPressed: () {
                    print("키워드 + 버튼 클릭됨");
                  },
                ),
              ],
            ),

            const Spacer(),

            // 24시: AI 생성 버튼
            // AI 생성 버튼
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("AI 생성"),
                        content: const Text("작성하신 키워드에 대해서 AI 그림 생성을 원하시나요?"),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // 팝업 닫기
                            },
                            child: const Text("아니요"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // 팝업 닫고
                              print("예 클릭됨"); // 예 눌렀을 때 실행
                              // 여기에 AI 생성 기능이 들어가면 됨
                            },
                            child: const Text("예"),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.bolt),
                label: const Text("AI 생성"),
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
