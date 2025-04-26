import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pages/starting/landing.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const SheepDiaryApp());
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
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ko', 'KR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const LandingPage(), // 항상 LandingPage에서 시작!
      debugShowCheckedModeBanner: false,
    );
  }
}