import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'review/review_page.dart';
import 'write/timeline.dart'; // ✅ WritePage import 추가
import '../data/diary_data.dart';
import 'package:intl/intl.dart';
import 'write/emoji.dart'; // ✅ 감정 이모지 다이얼로그 함수 import 추가
import '/pages/mypage/mypage.dart';
import 'write/diary_page.dart';
import 'package:provider/provider.dart';
import '../data/diary_provider.dart'; // 경로는 실제 위치에 맞게 조정
import '../../data/diary.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

extension DiaryModelExtension on Diary {
  DiaryEntry toDiaryEntry() {
    return DiaryEntry(
      date: date,
      text: text,
      tags: tags,
      photos: photos,
      latitude: latitude,
      longitude: longitude,

      timeline: timeline
          .map((e) => LatLng(e['lat'] ?? 0.0, e['lng'] ?? 0.0))
          .toList(),

      cameraTarget: LatLng(
        cameraTarget['lat'] ?? 0.0,
        cameraTarget['lng'] ?? 0.0,
      ),

      markers: markers.map((marker) {
        return Marker(
          markerId: MarkerId(marker['id'] ?? UniqueKey().toString()),
          position: LatLng(marker['lat'] ?? 0.0, marker['lng'] ?? 0.0),
        );
      }).toSet(),
    );
  }
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;


  void _onDateSelected(BuildContext context, DateTime selectedDay) {
    String dateKey = DateFormat('yyyy-MM-dd').format(selectedDay);

    final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);
    final diaries = diaryProvider.diaries;

    final diary = diaries.where((d) => d.date == dateKey).isNotEmpty
        ? diaries.firstWhere((d) => d.date == dateKey)
        : null;


    if (diary != null) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ReviewPage(entry: diary.toDiaryEntry()), // Diary → DiaryEntry 변환 필요
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("알림"),
            content: const Text("해당 날짜의 다이어리가 없습니다."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("확인"),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("🐑 Sheep Diary 📝"),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // ✅ 1. 검색창
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              keyboardType: TextInputType.text,
              autofillHints: null, // 자동완성 툴바 제거!
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: 'Search diary...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: (value) {
                print('검색어: $value');
              },
            ),
          ),

          // ✅ 2. 캘린더 UI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _onDateSelected(context, selectedDay);
                },
                eventLoader: (day) {
                  final dateKey = DateFormat('yyyy-MM-dd').format(day);
                  final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);
                  final hasDiary = diaryProvider.diaries.any((d) => d.date == dateKey);
                  return hasDiary ? [dateKey] : [];
                },
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isNotEmpty) {
                      return Positioned(
                        bottom: 1,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    return Center(
                      child: Text("🐑", style: TextStyle(fontSize: 24)),
                    );
                  },
                  defaultBuilder: (context, day, focusedDay) {
                    return Center(child: Text('${day.day}'));
                  },
                  todayBuilder: (context, day, focusedDay) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.lightBlue,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
            // 현재 페이지
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WritePage()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyPageScreen()),
              );
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
}



