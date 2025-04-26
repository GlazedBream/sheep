import 'package:flutter/material.dart';
import '../write/timeline.dart';
import '/pages/starting/login.dart'; // LoginPage import
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WritePage()),
      );
    });
  }
  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    final autoLogin = prefs.getBool('auto_login') ?? false; // 기본값 설정

    // autoLogin 값이 true이고 access_token이 존재하면 Timeline으로 이동
    if (autoLogin == true && accessToken != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WritePage()), // Timeline으로 변경
      );
    } else {
      // 그렇지 않으면 LoginPage로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Image.asset('assets/images/diary_cover.png'),
      ),
    );
  }
}