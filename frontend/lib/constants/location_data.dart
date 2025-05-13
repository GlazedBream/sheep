// location_data.dart
import 'package:latlong2/latlong.dart';

final Map<String, LatLng> locationMap = {
  "이태원": LatLng(37.5340, 126.9940),
  "홍대": LatLng(37.5563, 126.9220),
  "한강": LatLng(37.5283, 126.9326),
  "명동": LatLng(37.5609, 126.9862),
  "종로": LatLng(37.5716, 126.9768),
};

final Map<String, List<String>> locationImages = {
  "이태원": ['assets/images/test0.jpg', 'assets/images/test1.jpg'],
  "홍대": ['assets/images/test2.jpg', 'assets/images/test3.jpg'],
  "한강": ['assets/images/test4.jpg', 'assets/images/test5.jpg'],
  "명동": ['assets/images/test6.jpg', 'assets/images/test7.jpg'],
  "종로": ['assets/images/test8.jpg', 'assets/images/test9.jpg'],
};
