import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/templates.dart';

class ThemedScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final int? currentIndex;
  final void Function(int)? onTap;
  final List<Widget>? actions;
  final Widget? leading;
  final List<BottomNavigationBarItem>? navItems;


  const ThemedScaffold({
    super.key,
    required this.title,
    required this.child,
    this.currentIndex,
    this.onTap,
    this.actions,
    this.leading,
    this.navItems,
  });

  @override
  Widget build(BuildContext context) {
    final template = context.watch<TemplateProvider>().currentTemplate;

    return Scaffold(
      backgroundColor: template.backgroundColor,
      appBar: AppBar(
        backgroundColor: template.appBarColor,
        leading: leading,
        title: Text(title),
        centerTitle: true,
        actions: actions,
      ),
      body: SafeArea(
        child: child,
      ),
      bottomNavigationBar: currentIndex != null &&
          onTap != null &&
          navItems != null &&
          navItems!.isNotEmpty  // 빈 리스트 체크
          ? BottomNavigationBar(
        backgroundColor: template.appBarColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: currentIndex!,
        onTap: onTap!,
        items: navItems!,
      )
          : null,
    );
  }
}
