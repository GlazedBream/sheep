// 구매이력 페이지 (동일한 사진 박스 구조)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/themed_scaffold.dart';

/// 4. 구매이력 페이지
class PurchaseHistoryPage extends StatelessWidget {
  const PurchaseHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      title: '나의 구매내역',
      currentIndex: null, // 하단 내비게이션 없음
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: 3,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('test$index 선택됨')),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: AssetImage('assets/images/test$index.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}