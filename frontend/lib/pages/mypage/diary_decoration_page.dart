import 'package:flutter/material.dart';

/// DiaryDecorationPage (다꾸다꾸 스타일 리스트뷰)
class DiaryDecorationPage extends StatelessWidget {
  const DiaryDecorationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('다꾸다꾸'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Image.asset('assets/images/test$index.jpg', width: 60, height: 60, fit: BoxFit.cover),
              title: Text('다이어리 꾸미기 아이템 $index'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('아이템 $index 선택됨')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}