import 'package:flutter/material.dart';
import '/BaseScaffold.dart';
import '/pages/calendarscreen.dart';
import '/pages/write/timeline.dart';
import '/pages/starting/login.dart';
import 'editinfo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'diary_decoration_page.dart';
import 'purchase_history_page.dart';
import 'store_page.dart';
import 'terms_tabs_page.dart';
import 'package:test_sheep/pages/mypage/purchase_history_page.dart' as purchase;
import 'package:test_sheep/pages/mypage/store_page.dart' as store;

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🐑 My Page"),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 영역
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (BuildContext context) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text('갤러리에서 선택'),
                              onTap: () {
                                Navigator.pop(context);
                                print("갤러리 선택됨");
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.image),
                              title: const Text('기본 아이콘 선택'),
                              onTap: () {
                                Navigator.pop(context);
                                print("기본 아이콘 선택됨");
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/sheep.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TestUser',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'hong@email.com',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),
            const Text('설정',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            _buildButton(
              context,
              '개인정보 수정',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditInfoPage()),
                );
              },
            ),
            _buildButton(
              context,
              '이용약관, 개인정보동의서 및 AI처리방침',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TermsTabsPage()),
                );
              },
            ),

            const SizedBox(height: 24),
            const Text('기타',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            _buildButton(
              context,
              '다이어리 꾸미기',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DiaryDecorationPage()),
                );
              },
            ),
            _buildButton(
              context,
              'Store',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StorePage()),
                );
              },
            ),
            _buildButton(
              context,
              '구매 이력',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const purchase.PurchaseHistoryPage()),
                );
              },
            ),

            const SizedBox(height: 24),
            _buildBlueButton(context, '로그아웃'),
            _buildBlueButton(context, '디버깅용 Pref CLEAR/ 회원탈퇴'),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CalendarScreen()),
              );
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WritePage()),
              );
              break;
            case 2:
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


  Widget _buildButton(BuildContext context, String text, {VoidCallback? onTap}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap ??
                  () {
                print('$text 버튼 클릭됨');
              },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlueButton(BuildContext context, String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.lightBlue[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            print('$text 버튼 클릭됨');
            if (text == '로그아웃') {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); // SharedPreferences 데이터 초기화
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            } else if (text == '회원탈퇴') {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); // SharedPreferences 데이터 초기화
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Center(
              child: Text(
                text,
                style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
