// controllers/main_controller.dart
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainController extends GetxController {
  var userName = 'User Name'.obs;
  var userEmail = 'user@example.com'.obs;
  var userPicture =
      'https://img.freepik.com/free-vector/user-blue-gradient_78370-4692.jpg?t=st=1743582913~exp=1743586513~hmac=339d2b60234a1d30391a4041e477f3fffc50c49a67a3d217b83e1aebfc142869&w=740'
          .obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    userName.value = prefs.getString("userName") ?? "User Name";
    userEmail.value = prefs.getString("email") ?? "user@example.com";
    userPicture.value =
        prefs.getString("picture") ??
        "https://img.freepik.com/free-vector/user-blue-gradient_78370-4692.jpg?t=st=1743582913~exp=1743586513~hmac=339d2b60234a1d30391a4041e477f3fffc50c49a67a3d217b83e1aebfc142869&w=740";
  }

  void logout() {
    // Clear user data
    userName.value = '';
    userEmail.value = '';
    userPicture.value = '';

    // Navigate to login and clear all previous routes
    Get.offAllNamed('/login');
  }
}
