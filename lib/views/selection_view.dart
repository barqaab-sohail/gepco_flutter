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
    });
  }

  Future<Map<String, String?>> getUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      "userName": prefs.getString("userName"),
      "picture": prefs.getString("picture"),
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
      appBar: CustomAppBar(
        title: 'Selection View',
        pictureUrl: pictureUrl,
        onLogout: _logout,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Circle Dropdown
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
                        child: Text(circle.name ?? ''),
                      );
                    }).toList(),
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
              );
            }),
            SizedBox(height: 20),

            // Division Dropdown
            isLoadingDivisions
                ? CircularProgressIndicator()
                : DropdownButton<dynamic>(
                  isExpanded: true,
                  value: selectedDivision,
                  hint: Text("Select Division"),
                  items:
                      divisions.map((division) {
                        return DropdownMenuItem<dynamic>(
                          value: division,
                          child: Text(division['name'] ?? ''),
                        );
                      }).toList(),
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
                ),
            SizedBox(height: 20),

            // SubDivision Dropdown
            isLoadingSubDivisions
                ? CircularProgressIndicator()
                : DropdownButton<dynamic>(
                  isExpanded: true,
                  value: selectedSubDivision,
                  hint: Text("Select Sub Division"),
                  items:
                      subDivisions.map((subDivision) {
                        return DropdownMenuItem<dynamic>(
                          value: subDivision,
                          child: Text(subDivision['name'] ?? ''),
                        );
                      }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedSubDivision = newValue;
                      selectedFeeder = null;
                    });
                    if (newValue != null) {
                      loadFeeders(newValue['id'].toString());
                    }
                  },
                ),
            SizedBox(height: 20),

            // Feeder Dropdown
            isLoadingFeeders
                ? CircularProgressIndicator()
                : DropdownButton<dynamic>(
                  isExpanded: true,
                  value: selectedFeeder,
                  hint: Text("Select Feeder"),
                  items:
                      feeders.map((feeder) {
                        return DropdownMenuItem<dynamic>(
                          value: feeder,
                          child: Text(feeder['name'] ?? ''),
                        );
                      }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedFeeder = newValue;
                    });
                  },
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
