// widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/main_controller.dart';

class AppDrawer extends StatelessWidget {
  final MainController _mainController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Obx(
            () => UserAccountsDrawerHeader(
              accountName: Text(_mainController.userName.value),
              accountEmail: Text(_mainController.userEmail.value),
              currentAccountPicture: CircleAvatar(
                backgroundImage: NetworkImage(
                  _mainController.userPicture.value,
                ),
              ),
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            ),
          ),
          ListTile(
            leading: Icon(Icons.add),
            title: Text('Add New Record'),
            onTap: () {
              Get.toNamed('/add-record');
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Logout'),
            onTap: _mainController.logout,
          ),
        ],
      ),
    );
  }
}
