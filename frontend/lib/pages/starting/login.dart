import 'package:flutter/material.dart';
import 'signup.dart';
import '/pages/write/timeline.dart';
import 'splashscreen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _autoLogin = false; // 자동 로그인 상태 변수

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/auth/token/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        print("✅ 로그인 성공!");
        final data = jsonDecode(response.body);
        final accessToken = data['access'];
        final refreshToken = data['refresh'];

        if (accessToken == null || refreshToken == null) {
          throw Exception('토큰 값이 없습니다.');
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);
        await prefs.setString('refresh_token', refreshToken);
        await prefs.setBool('auto_login', _autoLogin);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SplashScreen()),
        );
      } else {
        print("❌ 로그인 실패: ${response.body}");
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('로그인 실패'),
            content: Text('이메일 또는 비밀번호가 잘못되었습니다.\n${response.body}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ 예외 발생: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('에러'),
          content: Text('로그인 중 에러가 발생했습니다.\n$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }
  // ✅ 자동 로그인 체크박스
  Widget _buildAutoLoginCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _autoLogin,
          onChanged: (value) {
            setState(() {
              _autoLogin = value ?? false;
            });
          },
        ),
        const Text('자동 로그인'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // 1. 배너 이미지
              const SizedBox(height: 40),
              Center(
                child: Image.asset(
                  'assets/images/banner.png', // 이미지 경로
                  height: 150,
                ),
              ),

              const SizedBox(height: 40),

              // 2. SNS 연동 로그인 (카카오, 네이버, 구글)
              //카카오 로그인 버튼
              ElevatedButton(
                onPressed: () {
                  // TODO: 카카오 로그인 연동
                  debugPrint('Kakao Login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE500),
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/icons/kakao.png', height: 24),
                    const SizedBox(width: 12),
                    const Text("카카오로 로그인"),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 네이버 로그인 버튼
              ElevatedButton(
                onPressed: () {
                  // TODO: 네이버 로그인 연동
                  debugPrint('Naver Login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF03C75A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/icons/naver.png', height: 24),
                    const SizedBox(width: 12),
                    const Text("네이버로 로그인"),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 구글 로그인 버튼
              ElevatedButton(
                onPressed: () {
                  // TODO: 구글 로그인 연동
                  debugPrint('Google Login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/icons/google.png', height: 24),
                    const SizedBox(width: 12),
                    const Text("Google로 로그인"),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 3. ID, 비밀번호 입력
              TextField(
                controller: _emailController, // 추가됨
                keyboardType: TextInputType.text,
                autofillHints: null, // 자동완성 툴바 제거!
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 10),

              _buildAutoLoginCheckbox(),

              ElevatedButton(
                onPressed: () {
                  debugPrint("Login with autoLogin: $_autoLogin");
                  _login(); // 함수 호출
                },
                child: const Text("Login"),
              ),

              const SizedBox(height: 20),

              // 4. 회원가입 안내
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignUpPage()),
                      );
                    },
                    child: const Text("Sign Up"),
                  ),
                ],
              ),

              // 🧪 Test 버튼
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SplashScreen(),
                    ),
                  );
                },
                child: const Text("Go to Timeline"),
              ),

            ],
          ),
        ),
      ),
    );
  }
}