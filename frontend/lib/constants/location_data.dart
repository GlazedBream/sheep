// location_data.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

// 위치별 좌표 정보
final Map<String, LatLng> locationMap = {
  "가평휴게소": LatLng(37.7136, 127.7317),
  "김유정 레일바이크": LatLng(37.7946, 127.8711),
  "산토리니 카페": LatLng(37.8914, 127.7765),
  "알파카월드": LatLng(37.8277, 127.8837),
  "뚜레한우": LatLng(37.8063, 127.9921),
  "집": LatLng(37.5532, 126.9433),
};

// 위치별 데모 이미지
final Map<String, List<String>> locationImages = {
  "김유정 레일바이크": ['assets/images/demo01.jpg', 'assets/images/demo02.jpg'],
  "산토리니 카페": ['assets/images/demo03.jpg', 'assets/images/demo04.jpg'],
  "알파카월드": ['assets/images/demo05.jpg', 'assets/images/demo06.jpg'],
};

// 데모 이미지에 대한 미리 정의된 키워드
final Map<String, Map<String, dynamic>> demoImageKeywords = {
  'assets/images/demo01.jpg': {
    'caption': 'Enjoying a peaceful ride on the Gimyujeong Rail Bike with beautiful mountain views.',
    'keywords': ['rail bike', 'scenic view', 'outdoor activity']
  },
  'assets/images/demo02.jpg': {
    'caption': 'The charming old train station at Gimyujeong with its nostalgic atmosphere.',
    'keywords': ['train station', 'historical site', 'rustic charm']
  },
  'assets/images/demo03.jpg': {
    'caption': 'A cozy corner at Cafe Santorini with delicious coffee and desserts.',
    'keywords': ['coffee', 'dessert', 'cafe interior']
  },
  'assets/images/demo04.jpg': {
    'caption': 'The beautiful blue and white themed exterior of Cafe Santorini.',
    'keywords': ['cafe exterior', 'blue theme', 'photogenic spot']
  },
  'assets/images/demo05.jpg': {
    'caption': 'Feeding and interacting with friendly alpacas at Alpaca World.',
    'keywords': ['alpaca', 'animal interaction', 'feeding']
  },
  'assets/images/demo06.jpg': {
    'caption': 'The scenic landscape of Alpaca World with animals grazing in the field.',
    'keywords': ['pasture', 'animals', 'nature view']
  },
};

// 하루 일정 타임라인
const List<String> locationTimeline = [
  "10:00 - 가평휴게소에서 아침식사",
  "11:00 - 춘천에서 김유정 레일바이크",
  "14:00 - 춘천에서 산토리니 카페",
  "15:30 - 홍천에서 알파카월드",
  "17:30 - 홍천 뚜레한우에서 저녁식사",
  "21:00 - 귀가",
];
