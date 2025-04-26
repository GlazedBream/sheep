// lib/main_navigation.dart
import 'package:flutter/material.dart';
import 'pages/write/timeline.dart';
import 'pages/calendarscreen.dart';
import 'pages/write/emoji.dart';
import 'pages/mypage/mypage.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 1; // 기본값을 Timeline으로 설정

  final DateTime _today = DateTime.now();
  final String _defaultEmotion = "😊";

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

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
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
}