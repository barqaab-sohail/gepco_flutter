import 'package:gepco_front_flutter/views/dashboard.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:gepco_front_flutter/services/api/base_api.dart';
import 'package:gepco_front_flutter/services/api/end_points.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_storage/get_storage.dart';
import 'package:gepco_front_flutter/models/circle_model.dart';
import 'package:gepco_front_flutter/views/selection_view.dart';

class LoginController extends GetxController {
  var emailController = TextEditingController();
  var passwordController = TextEditingController();
  var isLoading = false.obs;
  var rememberMe = false.obs;
  var circles = <Circle>[].obs; // Divisions List

  final storage = GetStorage();

  @override
  void onInit() {
    super.onInit();
    loadSavedCredentials();
  }

  void loadSavedCredentials() {
    if (storage.hasData("email") && storage.hasData("password")) {
      emailController.text = storage.read("email");
      passwordController.text = storage.read("password");
      rememberMe.value = true;
    }
  }

  void loginWithGetx() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Simulate an API call delay
    await Future.delayed(Duration(seconds: 2));

    if (rememberMe.value) {
      storage.write("email", emailController.text);
      storage.write("password", passwordController.text);
    } else {
      storage.remove("email");
      storage.remove("password");
    }
    try {
      var url = Uri.parse(BaseApi.baseURL + EndPoints.login);
      var response = await http.post(
        url,
        body: {
          'email': emailController.text,
          'password': passwordController.text,
        },
      );
      var data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        Get.snackbar(
          'Login Sucessfull',
          'Welcome',
          snackPosition: SnackPosition.BOTTOM,
        );

        //print(data['status']);
        await prefs.setInt("status", data["status"]);
        await prefs.setString("userName", data["userName"]);
        await prefs.setString("email", data["email"]);
        await prefs.setString("picture", data["picture"]);
        await prefs.setString("token", data["token"]);
        print(data['circles']);
        circles.value =
            (data['circles'] as List)
                .map((item) => Circle.fromJson(item))
                .toList();

        // Get.to(() => EarthingTableView());
        Get.toNamed('/dashboard');
        //Get.to(() => DashboardView());
      } else {
        print(data.toString());
        Get.snackbar(
          'Login Failed',
          data['message'],
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Exception',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      print('Error details: ${e.toString()}');
    } finally {
      isLoading.value = false; // Hide loading indicator
    }
  }
}
