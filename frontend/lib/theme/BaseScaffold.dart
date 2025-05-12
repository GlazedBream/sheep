import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'templates.dart';

class BaseScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const BaseScaffold({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final template = context.watch<TemplateProvider>().currentTemplate;

    return Scaffold(
      backgroundColor: template.backgroundColor,
      appBar: AppBar(
        backgroundColor: template.appBarColor,
        title: Text(title),
      ),
      body: SafeArea(child: child),
    );
  }
}
