import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api/base_api.dart';
import '../../services/api/end_points.dart';

class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(id: json['id'], name: json['name']);
  }
}

class TowerStructure {
  final int id;
  final String name;

  TowerStructure({required this.id, required this.name});

  factory TowerStructure.fromJson(Map<String, dynamic> json) {
    return TowerStructure(id: json['id'], name: json['name']);
  }
}

class EarthingTableController extends GetxController {
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController tageNoController = TextEditingController();
  final TextEditingController chemicalController = TextEditingController();
  final TextEditingController rodController = TextEditingController();
  final TextEditingController earthWireController = TextEditingController();
  final TextEditingController earthingBeforeController =
      TextEditingController();
  final TextEditingController earthingAfterController = TextEditingController();

  Rx<File?> image = Rx<File?>(null);
  RxList<Category> categories = <Category>[].obs;
  RxList<TowerStructure> towerStructures = <TowerStructure>[].obs;

  final Rxn<int> selectedCategoryId = Rxn<int>();
  final Rxn<int> selectedTowerStructureId = Rxn<int>();
  RxBool isLoading = false.obs;

  String? userName;
  String? pictureUrl;
  String? token;
  String feederName = '';
  String feederId = '';

  @override
  void onInit() {
    final Map<String, dynamic> feederData = Get.arguments ?? {};
    feederName = feederData['name'] ?? '';
    feederId = feederData['id']?.toString() ?? '';
    loadUserData().then((_) => loadDropdownData());
    super.onInit();
  }

  Future<void> loadUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    userName = prefs.getString("userName") ?? "Guest";
    pictureUrl = prefs.getString("picture") ?? "https://via.placeholder.com/50";
    token = prefs.getString("token");
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      File? croppedFile = await _cropImage(File(pickedFile.path));
      if (croppedFile != null) {
        image.value = croppedFile;
      }
    }
  }

  Future<File?> _cropImage(File imageFile) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.blue,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop Image'),
      ],
    );

    return croppedFile != null ? File(croppedFile.path) : null;
  }

  Future<void> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar("Error", "Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar("Error", "Location permissions are permanently denied.");
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    latitudeController.text = position.latitude.toString();
    longitudeController.text = position.longitude.toString();
  }

  Future<void> loadDropdownData() async {
    if (token == null) return;
    isLoading.value = true;

    try {
      final uri = Uri.parse('${BaseApi.baseURL}gepco/getdata');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        categories.value =
            (data['categories'] as List)
                .map((item) => Category.fromJson(item))
                .toList();
        towerStructures.value =
            (data['towerStructures'] as List)
                .map((item) => TowerStructure.fromJson(item))
                .toList();
      } else {
        Get.snackbar("Error", "Failed to load dropdown data");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void resetForm() {
    image.value = null;
    selectedCategoryId.value = null;
    selectedTowerStructureId.value = null;

    latitudeController.clear();
    longitudeController.clear();
    locationController.clear();
    tageNoController.clear();
    chemicalController.clear();
    rodController.clear();
    earthWireController.clear();
    earthingBeforeController.clear();
    earthingAfterController.clear();
  }

  Future<void> uploadData() async {
    if (image.value == null ||
        selectedCategoryId.value == null ||
        selectedTowerStructureId.value == null ||
        tageNoController.text.isEmpty ||
        chemicalController.text.isEmpty ||
        rodController.text.isEmpty ||
        earthWireController.text.isEmpty ||
        earthingAfterController.text.isEmpty) {
      Get.snackbar(
        "Error",
        "Please fill all required fields and select image.",
      );
      return;
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(BaseApi.baseURL + EndPoints.earthingDetail),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields.addAll({
        'feeder_id': feederId,
        'category_id': selectedCategoryId.value.toString(),
        'tower_structure_id': selectedTowerStructureId.value.toString(),
        'latitude': latitudeController.text,
        'longitude': longitudeController.text,
        'tage_no': tageNoController.text,
        'chemical': chemicalController.text,
        'rod': rodController.text,
        'earth_wire': earthWireController.text,
        'earthing_after': earthingAfterController.text,
        'location': locationController.text,
        'earthing_before': earthingBeforeController.text,
      });

      request.files.add(
        await http.MultipartFile.fromPath('image', image.value!.path),
      );

      var response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        Get.snackbar("Success", "Upload successful!");
        resetForm();
      } else {
        Get.snackbar("Error", "Upload failed: $responseBody");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }
}
