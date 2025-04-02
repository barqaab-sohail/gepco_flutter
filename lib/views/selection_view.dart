import 'package:flutter/material.dart';
import 'package:gepco_front_flutter/controllers/login_controller.dart';
import 'package:get/get.dart';
import 'package:gepco_front_flutter/models/circle_model.dart';
import 'package:gepco_front_flutter/models/division_model.dart';
import 'package:gepco_front_flutter/models/sub_division_model.dart';
import 'package:gepco_front_flutter/models/feeder_model.dart';
import 'package:gepco_front_flutter/views/earthing_table_view.dart';
import 'package:gepco_front_flutter/widgets/custom_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gepco_front_flutter/views/login_view.dart';
import 'package:gepco_front_flutter/services/api/base_api.dart';
import 'package:gepco_front_flutter/services/api/end_points.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';

class SelectionView extends StatefulWidget {
  @override
  _SelectionViewState createState() => _SelectionViewState();
}

class _SelectionViewState extends State<SelectionView> {
  final LoginController loginController = Get.find<LoginController>();
  Circle? selectedCircle;
  dynamic selectedDivision;
  dynamic selectedSubDivision;
  dynamic selectedFeeder;
  String? pictureUrl;
  String? token;
  String? userName;
  List<dynamic> divisions = [];
  List<dynamic> subDivisions = [];
  List<dynamic> feeders = [];
  bool isLoadingDivisions = false;
  bool isLoadingSubDivisions = false;
  bool isLoadingFeeders = false;

  Future<void> _loadUserData() async {
    final userData = await getUserData();
    setState(() {
      userName = userData["userName"] ?? "Guest";
      pictureUrl = userData["picture"] ?? "https://via.placeholder.com/50";
      token = userData['token'];
    });
  }

  Future<Map<String, String?>> getUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      "userName": prefs.getString("userName"),
      "picture": prefs.getString("picture"),
      "token": prefs.getString("token"),
    };
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginView()),
      (route) => false,
    );
  }

  Future<List<dynamic>> fetchData(String endpoint, String parentId) async {
    try {
      final response = await http.get(
        Uri.parse('${BaseApi.baseURL}$endpoint/$parentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
      Get.snackbar(
        "Error",
        "Failed to load data",
        snackPosition: SnackPosition.BOTTOM,
      );
      return [];
    }
  }

  Future<void> loadDivisions(String circleId) async {
    setState(() {
      isLoadingDivisions = true;
      divisions = [];
      selectedDivision = null;
      subDivisions = [];
      selectedSubDivision = null;
      feeders = [];
      selectedFeeder = null;
    });

    final data = await fetchData(EndPoints.divisions, circleId);

    setState(() {
      divisions = data;
      isLoadingDivisions = false;
    });
  }

  Future<void> loadSubDivisions(String divisionId) async {
    setState(() {
      isLoadingSubDivisions = true;
      subDivisions = [];
      selectedSubDivision = null;
      feeders = [];
      selectedFeeder = null;
    });

    final data = await fetchData(EndPoints.subdivisions, divisionId);

    setState(() {
      subDivisions = data;
      isLoadingSubDivisions = false;
    });
  }

  Future<void> loadFeeders(String subDivisionId) async {
    setState(() {
      isLoadingFeeders = true;
      feeders = [];
      selectedFeeder = null;
    });

    final data = await fetchData(EndPoints.feeders, subDivisionId);

    setState(() {
      feeders = data;
      isLoadingFeeders = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: CustomAppBar(
      //   title: 'Selection View',
      //   pictureUrl: pictureUrl,
      //   onLogout: _logout,
      // ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Circle DropdownSearch
            Obx(() {
              if (loginController.circles.isEmpty) {
                return Center(child: CircularProgressIndicator());
              }
              return DropdownSearch<Circle>(
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      hintText: "Search circle...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                items: (filter, infiniteScrollProps) => loginController.circles,
                compareFn: (item1, item2) => item1.id == item2.id,
                itemAsString: (Circle circle) => circle.name ?? '',
                decoratorProps: DropDownDecoratorProps(
                  decoration: InputDecoration(
                    labelText: "Select Circle",
                    border: OutlineInputBorder(),
                  ),
                ),
                onChanged: (Circle? newValue) {
                  setState(() {
                    selectedCircle = newValue;
                    selectedDivision = null;
                    selectedSubDivision = null;
                    selectedFeeder = null;
                  });
                  if (newValue != null) {
                    loadDivisions(newValue.id.toString());
                  }
                },
                selectedItem: selectedCircle,
              );
            }),
            SizedBox(height: 20),

            // Division DropdownSearch
            isLoadingDivisions
                ? CircularProgressIndicator()
                : DropdownSearch<dynamic>(
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        hintText: "Search division...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  items: (filter, infiniteScrollProps) => divisions,
                  compareFn: (item1, item2) => item1['id'] == item2['id'],
                  itemAsString: (item) => item['name'] ?? '',
                  decoratorProps: DropDownDecoratorProps(
                    decoration: InputDecoration(
                      labelText: "Select Division",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  onChanged: (newValue) {
                    setState(() {
                      selectedDivision = newValue;
                      selectedSubDivision = null;
                      selectedFeeder = null;
                    });
                    if (newValue != null) {
                      loadSubDivisions(newValue['id'].toString());
                    }
                  },
                  selectedItem: selectedDivision,
                ),
            SizedBox(height: 20),

            // SubDivision DropdownSearch
            isLoadingSubDivisions
                ? CircularProgressIndicator()
                : DropdownSearch<dynamic>(
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        hintText: "Search sub division...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  items: (filter, infiniteScrollProps) => subDivisions,
                  compareFn: (item1, item2) => item1['id'] == item2['id'],
                  itemAsString: (item) => item['name'] ?? '',
                  decoratorProps: DropDownDecoratorProps(
                    decoration: InputDecoration(
                      labelText: "Select Sub Division",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  onChanged: (newValue) {
                    setState(() {
                      selectedSubDivision = newValue;
                      selectedFeeder = null;
                    });
                    if (newValue != null) {
                      loadFeeders(newValue['id'].toString());
                    }
                  },
                  selectedItem: selectedSubDivision,
                ),
            SizedBox(height: 20),

            // Feeder DropdownSearch
            isLoadingFeeders
                ? CircularProgressIndicator()
                : DropdownSearch<dynamic>(
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        hintText: "Search feeder...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  items: (filter, infiniteScrollProps) => feeders,
                  compareFn: (item1, item2) => item1['id'] == item2['id'],
                  itemAsString: (item) => item['name'] ?? '',
                  decoratorProps: DropDownDecoratorProps(
                    decoration: InputDecoration(
                      labelText: "Select Feeder",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  onChanged: (newValue) {
                    setState(() {
                      selectedFeeder = newValue;
                    });
                  },
                  selectedItem: selectedFeeder,
                ),
            SizedBox(height: 40),

            // Next Button
            ElevatedButton(
              onPressed:
                  selectedFeeder != null
                      ? () {
                        Get.to(
                          () => EarthingTableView(),
                          arguments: {
                            "id": selectedFeeder['id'],
                            "name": selectedFeeder['name'],
                          },
                        );
                      }
                      : null,
              child: Text("Next"),
            ),
          ],
        ),
      ),
    );
  }
}
