import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart'; // 추가!
import 'data/diary_provider.dart'; // 추가! (너가 만든 DiaryProvider 파일 경로에 맞춰야 해)
import 'pages/starting/landing.dart'; // 추가! (LandingPage 위치에 맞춰야 해)
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final envFile = File('.env');
  if (await envFile.exists()) {
    print(".env file found!");
  } else {
    print(".env file not found!");
  }
  await dotenv.load(); // .env 파일 로드

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TemplateProvider()),
        ChangeNotifierProvider(create: (_) => DiaryProvider()), // Provider 등록
      ],
      child: const SheepDiaryApp(), // 원래 너가 만든 SheepDiaryApp 사용
    ),
  );
}

class SheepDiaryApp extends StatelessWidget {
  const SheepDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sheep Diary',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('en', 'US'), Locale('ko', 'KR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const LandingPage(), // 그대로 유지
      debugShowCheckedModeBanner: false,
    );
  }
}
