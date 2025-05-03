// 이용약관, 개인정보, AI방침을 탭으로 구분
import 'package:flutter/material.dart';

/// 1. 이용약관/개인정보동의서/AI처리방침 페이지
class TermsTabsPage extends StatefulWidget {
  const TermsTabsPage({super.key});

  @override
  State<TermsTabsPage> createState() => _TermsTabsPageState();
}

class _TermsTabsPageState extends State<TermsTabsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = ['이용약관', '개인정보동의서', 'AI처리방침'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildTabContent(String title) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Text(
          '주용민배고파',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('정책 문서'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((title) => Tab(text: title)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((title) => _buildTabContent(title)).toList(),
      ),
    );
  }
}