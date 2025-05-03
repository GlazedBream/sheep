// location_data.dart
import 'package:latlong2/latlong.dart';

final Map<String, LatLng> locationMap = {
  "Itaewon": LatLng(37.5340, 126.9940),
  "Hongdae": LatLng(37.5563, 126.9220),
  "Han River": LatLng(37.5283, 126.9326),
  "Myeongdong": LatLng(37.5609, 126.9862),
  "Friends": LatLng(37.5716, 126.9768),
};

final Map<String, List<String>> locationImages = {
  "Itaewon": ['assets/images/test0.jpg', 'assets/images/test1.jpg'],
  "Hongdae": ['assets/images/test2.jpg', 'assets/images/test3.jpg'],
  "Han River": ['assets/images/test4.jpg', 'assets/images/test5.jpg'],
  "Myeongdong": ['assets/images/test6.jpg', 'assets/images/test7.jpg'],
  "Friends": ['assets/images/test8.jpg', 'assets/images/test9.jpg'],
};
