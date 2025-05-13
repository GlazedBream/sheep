import 'package:flutter/material.dart';
import '../../theme/themed_scaffold.dart'; // ThemedScaffold 임포트

class StorePage extends StatelessWidget {
  const StorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      title: 'SheepDiary 🐑',
      currentIndex: null, // 바텀바 없음
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () {},
        ),
      ],
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Image.asset(
                'assets/images/test$index.jpg',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
              title: Text('스토어 아이템 $index'),
              subtitle: const Text('₩3,000'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('스토어 아이템 $index 클릭됨')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// PurchaseHistoryPage (구매이력 스타일)
class PurchaseHistoryPage extends StatelessWidget {
  const PurchaseHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      title: '나의 구매내역',
      currentIndex: null,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {},
        ),
      ],
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Image.asset(
                'assets/images/test$index.jpg',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
              title: Text('구매한 아이템 $index'),
              subtitle: const Text('2024.04.01 · ₩3,000'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('구매 이력 아이템 $index 클릭됨')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
