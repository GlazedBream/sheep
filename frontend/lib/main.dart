import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NaverMapSdk.instance.initialize(clientId: 'YOUR_NAVER_MAP_CLIENT_ID'); // 여기도 동일하게!
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: NaverMapPage(),
    );
  }
}

class NaverMapPage extends StatelessWidget {
  const NaverMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: NaverMap(),
    );
  }
}

