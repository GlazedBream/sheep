// lib/main_navigation.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/write/timeline.dart';
import 'pages/calendarscreen.dart';
import 'pages/write/emoji.dart';
import 'pages/mypage/mypage.dart';
import 'theme/templates.dart';
import 'theme/themed_scaffold.dart'; // 여기 꼭 확인해

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 1; // 기본값을 Timeline으로 설정

  final DateTime _today = DateTime.now();
  final String _defaultEmotion = "😊";

  final List<String> _titles = ['Review', 'Timeline', 'My Page'];

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      const CalendarScreen(),
      WritePage(
        emotionEmoji: _defaultEmotion,
        selectedDate: _today,
      ),
      const MyPageScreen(),
    ];

    return ThemedScaffold(
      title: _titles[_currentIndex],
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      navItems: const [ // ✅ 3개 네비게이션 아이템 명시
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Review'),
        BottomNavigationBarItem(icon: Icon(Icons.timeline), label: 'Timeline'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'My Page'),
      ],
      child: _screens[_currentIndex],
    );
  }
}