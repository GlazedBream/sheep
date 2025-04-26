import 'dart:async';
import 'package:flutter/material.dart';
import '../../main_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'splashscreen.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  void initState() {
    super.initState();
    _handleStartupFlow();
  }

  Future<void> _handleStartupFlow() async {
    await Future.delayed(const Duration(seconds: 2)); // Splash 연출

    final prefs = await SharedPreferences.getInstance();
    final isAgreed = prefs.getBool('is_agreed') ?? false;

    if (!isAgreed) {
      _showAgreementDialog(prefs);
    } else {
      _checkLoginStatus(prefs); // ⬅️ 여기에서 JWT + auto_login으로 판별
    }
  }

  void _checkLoginStatus(SharedPreferences prefs) {
    final token = prefs.getString('jwt_token');
    final autoLogin = prefs.getBool('auto_login') ?? false;

    if (token != null && autoLogin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SplashScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  void _showAgreementDialog(SharedPreferences prefs) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('이용약관 동의'),
        content: const Text(
          '앱을 사용하려면 이용약관 및 위치정보 수집에 동의하셔야 합니다.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              prefs.setBool('is_agreed', true); // 동의 저장
              Navigator.pop(context);
              _checkLoginStatus(prefs);
            },
            child: const Text('동의'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 선택사항: 앱 종료 등
            },
            child: const Text('거부'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/app_cover.png',
              width: MediaQuery.of(context).size.width * 0.8,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            const Text(
              '앱 로딩 중...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
