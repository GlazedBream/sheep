import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/templates.dart'; // 템플릿 정보
import '../../theme/themed_scaffold.dart';

/// DiaryDecorationPage (다꾸다꾸 스타일 리스트뷰)
class DiaryDecorationPage extends StatelessWidget {
  const DiaryDecorationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      title: '다이어리 꾸미기',
      currentIndex: 0,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: allTemplates.length, // 이미지 갯수만큼 반복
        itemBuilder: (context, index) {
          final template = allTemplates[index]; // 템플릿 객체 가져오기
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Image.asset(
                template.imagePath, // 해당 이미지 경로 사용
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
              title: Text(template.name),
              onTap: () {
                context.read<TemplateProvider>().setTemplate(template);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${template.name} 템플릿이 적용되었습니다'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}