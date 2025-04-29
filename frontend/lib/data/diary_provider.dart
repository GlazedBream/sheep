// import 'package:flutter/material.dart';
// import 'diary.dart'; // 위에 만든 Diary 모델
//
// class DiaryProvider with ChangeNotifier {
//   final List<Diary> _diaries = [];
//
//   List<Diary> get diaries => [..._diaries];
//
//   // 특정 날짜에 해당하는 다이어리 찾기
//   Diary getDiaryByDate(DateTime date) {
//     return _diaries.firstWhere(
//           (diary) => diary.date == date,
//       orElse: () => Diary.empty(), // Diary 클래스에 empty 생성자 필요
//     );
//   }
//
//   // 다이어리 저장
//   void addDiary(Diary diary) {
//     _diaries.add(diary);
//     notifyListeners();
//   }
//
//   // 다이어리 수정
//   void updateDiary(Diary updatedDiary) {
//     final index = _diaries.indexWhere((diary) => diary.id == updatedDiary.id);
//     if (index != -1) {
//       _diaries[index] = updatedDiary;
//       notifyListeners();
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'diary.dart';

class DiaryProvider with ChangeNotifier {
  // 내부에서 다이어리 리스트를 관리
  final List<Diary> _diaries = [];


  // 외부에서 읽기 위한 getter
  List<Diary> get diaries => List.unmodifiable(_diaries);

  // 다이어리 추가
  void addDiary(Diary diary) {
    _diaries.add(diary);
    notifyListeners();
  }

  // 다이어리 수정
  void updateDiary(Diary updatedDiary) {
    final index = _diaries.indexWhere((d) => d.id == updatedDiary.id);
    if (index != -1) {
      _diaries[index] = updatedDiary;
      notifyListeners();
    }
  }

  // 다이어리 삭제
  void deleteDiary(String id) {
    _diaries.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  // 특정 날짜의 다이어리 찾기
  Diary? getDiaryByDate(String date) {
    return _diaries.firstWhere(
          (d) => d.date == date,
      orElse: () => Diary.empty(),
    );
  }

  void addOrUpdateDiary(Diary diary) {
    final index = _diaries.indexWhere((d) => d.id == diary.id);
    if (index != -1) {
      _diaries[index] = diary;
    } else {
      _diaries.add(diary);
    }
    notifyListeners();
  }
}