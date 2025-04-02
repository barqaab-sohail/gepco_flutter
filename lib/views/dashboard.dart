import 'package:flutter/material.dart';
import 'package:gepco_front_flutter/services/classes/scaffold_with_drawer.dart';
import 'package:get/get.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  Widget build(BuildContext context) {
    // Remove any Scaffold from the body content
    return ScaffoldWithDrawer(
      title: 'Dashboard', // Single title
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Dashboard Content'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Get.toNamed('/add-record'),
              child: Text('Add New Record'),
            ),
          ],
        ),
      ),
    );
  }
}
