// widgets/scaffold_with_drawer.dart
import 'package:flutter/material.dart';
import 'package:gepco_front_flutter/widgets/app_drawer.dart';

class ScaffoldWithDrawer extends StatelessWidget {
  final Widget body;
  final String title;
  final List<Widget>? actions;

  const ScaffoldWithDrawer({
    Key? key,
    required this.body,
    required this.title,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blue,
        actions: actions,
      ),
      drawer: AppDrawer(),
      body: body, // This should NOT contain another Scaffold
    );
  }
}
