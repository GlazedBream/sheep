import 'package:flutter/material.dart';
import 'purchase_history_page.dart';

/// StorePage (구름 AppBar 스타일, 가격 포함 리스트뷰)
/// StorePage (구름 AppBar 스타일, 가격 포함 리스트뷰)
class StorePage extends StatelessWidget {
  const StorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[300],
        title: const Text('SheepDiary 🐑'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.edit),
      ),
    );
  }
}

/// PurchaseHistoryPage (구매이력 스타일)
class PurchaseHistoryPage extends StatelessWidget {
  const PurchaseHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 구매내역'),
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
