import 'package:flutter/material.dart';
import 'package:gepco_front_flutter/controllers/login_controller.dart';
import 'package:get/get.dart';
import 'package:gepco_front_flutter/models/circle_model.dart';
import 'package:gepco_front_flutter/views/earthing_table_view.dart';
import 'package:gepco_front_flutter/widgets/custom_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gepco_front_flutter/views/login_view.dart';

class CircleView extends StatefulWidget {
  @override
  _CircleViewState createState() => _CircleViewState();
}

class _CircleViewState extends State<CircleView> {
  final LoginController loginController = Get.find<LoginController>();
  Circle? selectedCircle; // Selected Division Object
  String? pictureUrl;
  String? userName;

  Future<void> _loadUserData() async {
    final userData = await getUserData();
    setState(() {
      userName = userData["userName"] ?? "Guest";
      pictureUrl =
          userData["picture"] ??
          "https://via.placeholder.com/50"; // Default image
    });
  }

  Future<Map<String, String?>> getUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      "userName": prefs.getString("userName"),
      "picture": prefs.getString("picture"),
    };
  }

  //logout function
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all stored data

    // Navigate to login page and remove previous pages from stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginView()),
      (route) => false, // This removes all previous routes
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Selection View',
        pictureUrl: pictureUrl,
        onLogout: _logout,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Obx(() {
              if (loginController.circles.isEmpty) {
                return Center(child: CircularProgressIndicator());
              }
              return DropdownButton<Circle>(
                isExpanded: true,
                value: selectedCircle,
                hint: Text("Select Circle"),
                items:
                    loginController.circles.map((Circle circle) {
                      return DropdownMenuItem<Circle>(
                        value: circle,
                        child: Text(circle.name ?? ''), // Show Circle Name
                      );
                    }).toList(),
                onChanged: (Circle? newValue) {
                  setState(() {
                    selectedCircle = newValue;
                  });
                },
              );
            }),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (selectedCircle != null) {
                  // Navigate to Next Screen with Division Info
                  Get.to(
                    () => EarthingTableView(),
                    arguments: {
                      "id": selectedCircle!.id,
                      "name": selectedCircle!.name,
                    },
                  );
                } else {
                  Get.snackbar(
                    "Error",
                    "Please select a division first",
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
              child: Text("Next"),
            ),
          ],
        ),
      ),
    );
  }
}
