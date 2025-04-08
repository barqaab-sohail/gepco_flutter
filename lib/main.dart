import 'package:flutter/material.dart';
import 'package:gepco_front_flutter/views/dashboard.dart';
import 'package:gepco_front_flutter/views/login_view.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:gepco_front_flutter/services/classes/scaffold_with_drawer.dart';
import 'package:gepco_front_flutter/controllers/main_controller.dart';
import 'package:gepco_front_flutter/views/selection_view.dart';

void main() async {
  await GetStorage.init();
  runApp(MyApp());
}

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(
//       title: 'GEPCO Earthing Validation App',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: const LoginView(),
//     );
//   }
// }

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'My App',
      initialRoute: '/login',
      debugShowCheckedModeBanner: false,
      getPages: [
        GetPage(name: '/login', page: () => LoginView()),
        GetPage(
          name: '/dashboard',
          page:
              () =>
                  ScaffoldWithDrawer(title: 'Dashboard', body: DashboardView()),
        ),
        GetPage(
          name: '/add-record',
          page:
              () => ScaffoldWithDrawer(
                title: 'Add New Record',
                body: SelectionView(),
              ),
        ),
      ],
      initialBinding: BindingsBuilder(() {
        Get.put(MainController());
      }),
    );
  }
}
