import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  File? _profileImage;
  String _selectedGender = ""; // 실제 선택된 성별 값
  bool _isEmailVerified = false;
  bool _isCodeSent = false;
  final picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _password2Controller = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _signUp() async {
    final name = _nameController.text;
    final email = _emailController.text;
    final code = _codeController.text;
    final password = _passwordController.text;
    final password2 = _password2Controller.text;
    final gender = _genderController.text;
    final birthday = _birthdayController.text;


    if (password != password2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호가 일치하지 않습니다')),
      );
      return;
    }

    final uri = Uri.parse('http://10.0.2.2:8000/api/auth/signup/'); // API 주소로 바꿔줘!
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_name': name,
        'email': email,
        'password': password,
        'password2': password2,
        'gender': gender,
        'birthday': birthday,
      }),
    );

    if (response.statusCode == 201) {
      print("✅ 회원가입 성공!");
      final resBody = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원가입 성공')),
      );
      // Navigator.push... // 로그인 화면으로 이동할 수도 있음
    } else {
      final errorBody = json.decode(response.body);
      print("❌ 로그인 실패: $errorBody");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('에러 발생: ${errorBody['error'] ?? '알 수 없는 오류'}')),
      );
    }
  }

  Future<void> _sendVerificationCode() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일을 입력해주세요')),
      );
      return;
    }

    final uri = Uri.parse('http://10.0.2.2:8000/api/auth/send-code/'); // 여기에 이메일 인증코드 발송 API 주소 입력
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    if (response.statusCode == 200) {
      print("✅ 인증번호 전송 성공!"); // ← 이거 꼭 추가
      setState(() {
        _isCodeSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증번호가 발송되었습니다')),
      );
    } else {
      final errorBody = json.decode(response.body);
      print("❌ 로그인 실패: $errorBody");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('에러 발생: ${errorBody['error'] ?? '알 수 없는 오류'}')),
      );
    }
  }

  Future<void> _verifyAuthCode() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();

    if (email.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일과 인증번호를 모두 입력해주세요')),
      );
      return;
    }

    final uri = Uri.parse('http://10.0.2.2:8000/api/auth/verify-code/');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'code': code,
      }),
    );

    // print("🔍 Response status: ${response.statusCode}");
    print(utf8.decode(response.bodyBytes));
    // print("🔍 Response body: ${response.body}");

    if (response.statusCode == 200) {
      print("✅ 이메일 인증 성공!");
      setState(() {
        _isEmailVerified = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일 인증이 완료되었습니다')),
      );
    } else {
      try {
        final errorBody = json.decode(response.body);
        print("❌ 로그인 실패: $errorBody");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('인증 실패: ${errorBody['error'] ?? '잘못된 코드입니다'}')),
        );
      } catch (e) {
        print("❌ JSON 파싱 실패: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('인증 실패: 서버 응답을 처리할 수 없습니다')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 프로필 이미지
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage:
                  _profileImage != null ? FileImage(_profileImage!) : null,
                  child: _profileImage == null
                      ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. 이름
            TextField(
              controller: _nameController,
              keyboardType: TextInputType.text,
              autofillHints: null, // 자동완성 툴바 제거!
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(labelText: '이름'),
            ),
            const SizedBox(height: 16),

            // 3. 이메일 + 인증 버튼
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.text,
                    autofillHints: null, // 자동완성 툴바 제거!
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: const InputDecoration(labelText: '이메일'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sendVerificationCode,
                  child: const Text("인증"),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (_isCodeSent)
              const Text(
                "✅ 인증번호가 전송되었습니다.",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),

            // 4. 인증번호 입력 + 확인 버튼
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.text,
                    autofillHints: null, // 자동완성 툴바 제거!
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: const InputDecoration(labelText: '인증번호 입력'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _verifyAuthCode,
                  child: const Text("확인"),
                ),

              ],
            ),

            const SizedBox(height: 8),

// ✅ 인증 완료 메시지 표시
            if (_isEmailVerified)
              const Text(
                "✅ 이메일 인증이 완료되었습니다.",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),

            // 5. 비밀번호
            TextField(
              controller: _passwordController,
              keyboardType: TextInputType.text,
              autofillHints: null, // 자동완성 툴바 제거!
              enableSuggestions: false,
              autocorrect: false,
              obscureText: true,
              decoration: const InputDecoration(labelText: '비밀번호'),
            ),
            const SizedBox(height: 16),

            // 6. 비밀번호 확인
            TextField(
              controller: _password2Controller,
              keyboardType: TextInputType.text,
              autofillHints: null, // 자동완성 툴바 제거!
              enableSuggestions: false,
              autocorrect: false,
              obscureText: true,
              decoration: const InputDecoration(labelText: '비밀번호 확인'),
            ),
            const SizedBox(height: 16),

            // 7. 성별 선택
            const Text("성별"),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("남성"),
                    value: "male",
                    groupValue: _selectedGender,
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value!;
                        _genderController.text = value; // controller에 값 저장
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("여성"),
                    value: "female",
                    groupValue: _selectedGender,
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value!;
                        _genderController.text = value; // controller에 값 저장
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 8. 생년월일
            TextField(
              controller: _birthdayController,
              readOnly: true,
              decoration: const InputDecoration(labelText: '생년월일'),
              onTap: () async {
                FocusScope.of(context).requestFocus(FocusNode()); // 키보드 안 뜨게
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)), // 20살 기준
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                  locale: const Locale('ko', 'KR'), // 한국어 로컬 설정 (원하면)
                );
                if (pickedDate != null) {
                  setState(() {
                    // 포맷 적용해서 TextField에 넣기
                    String birthdayFormatted = DateFormat('yyyy-MM-dd').format(pickedDate);
                    _birthdayController.text = birthdayFormatted;
                  });
                }
              },
            ),
            const SizedBox(height: 24),


            // 9. 가입 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _signUp,
                child: const Text("회원가입"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

