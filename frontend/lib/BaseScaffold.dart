// base_scaffold.dart
import 'package:flutter/material.dart';

class BaseScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const BaseScaffold({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(child: child),
    );
  }
}