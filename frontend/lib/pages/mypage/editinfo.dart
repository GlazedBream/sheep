import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/templates.dart';
import '../../theme/themed_scaffold.dart';

class EditInfoPage extends StatefulWidget {
  const EditInfoPage({super.key});

  @override
  State<EditInfoPage> createState() => _EditInfoPageState();
}

class _EditInfoPageState extends State<EditInfoPage> {
  final _formKey = GlobalKey<FormState>();

  String name = 'TestUser';
  String email = 'seongmin@example.com';
  String password = 'qwer1234';
  String phone = '010-1234-5678';
  String region = '서울';

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 키보드를 먼저 내리기
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
          FocusManager.instance.primaryFocus!.unfocus();
          return false; // 페이지 pop 하지 않음
        }
        return true; // 키보드가 안 떠있을 때만 pop
      },
      child: ThemedScaffold(
        title: '개인정보 수정',
        currentIndex: null,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // 이름
                TextFormField(
                  initialValue: name,
                  keyboardType: TextInputType.text,
                  autofillHints: null, // 자동완성 툴바 제거!
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: '이름'),
                  onChanged: (value) => name = value,
                ),
                const SizedBox(height: 16),

                // 이메일 (수정 불가)
                TextFormField(
                  initialValue: email,
                  keyboardType: TextInputType.text,
                  autofillHints: null, // 자동완성 툴바 제거!
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: '이메일'),
                  onChanged: (value) => email = value,
                ),
                const SizedBox(height: 16),

                // 비밀번호
                TextFormField(
                  initialValue: password,
                  keyboardType: TextInputType.text,
                  autofillHints: null, // 자동완성 툴바 제거!
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: '비밀번호'),
                  onChanged: (value) => password = value,
                ),
                const SizedBox(height: 16),

                // 전화번호
                TextFormField(
                  initialValue: phone,
                  keyboardType: TextInputType.text,
                  autofillHints: null, // 자동완성 툴바 제거!
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: '전화번호'),
                  onChanged: (value) => phone = value,
                ),
                const SizedBox(height: 30),

                // 지역
                TextFormField(
                  initialValue: region,
                  decoration: const InputDecoration(labelText: '지역'),
                  keyboardType: TextInputType.text,
                  autofillHints: null, // 자동완성 툴바 제거!
                  enableSuggestions: false,
                  autocorrect: false,
                  onChanged: (value) => region = value,
                ),
                const SizedBox(height: 30),

                // 저장 버튼
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // 서버 전송 로직 또는 로컬 저장
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('정보가 저장되었습니다!')),
                      );
                    }
                  },
                  child: const Text('저장'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}