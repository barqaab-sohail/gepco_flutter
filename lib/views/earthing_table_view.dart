import 'package:flutter/material.dart';
import 'package:gepco_front_flutter/views/login_view.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:gepco_front_flutter/services/api/base_api.dart';
import 'package:gepco_front_flutter/services/api/end_points.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:gepco_front_flutter/widgets/custom_app_bar.dart';

class EarthingTableView extends StatefulWidget {
  const EarthingTableView({super.key});

  @override
  State<EarthingTableView> createState() => _EarthingTableViewState();
}

class _EarthingTableViewState extends State<EarthingTableView> {
  final TextEditingController textEditingController = TextEditingController();
  File? _image;
  String? userName;
  String? pictureUrl;
  String? token;
  late String feederName;
  late String feederId;

  // Controllers for all fields
  TextEditingController latitudeController = TextEditingController();
  TextEditingController longitudeController = TextEditingController();
  TextEditingController subDivisionIdController = TextEditingController();
  TextEditingController categoryIdController = TextEditingController();
  TextEditingController towerStructureIdController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  TextEditingController tageNoController = TextEditingController();
  TextEditingController chemicalController = TextEditingController();
  TextEditingController rodController = TextEditingController();
  TextEditingController earthWireController = TextEditingController();
  TextEditingController earthingBeforeController = TextEditingController();
  TextEditingController earthingAfterController = TextEditingController();

  // Function to pick and crop image
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 100,
      maxWidth: 1080, // Adjust resolution
      maxHeight: 1920,
    );

    if (pickedFile != null) {
      File? croppedFile = await _cropImage(File(pickedFile.path));
      if (croppedFile != null) {
        setState(() {
          _image = croppedFile;
        });
      }
    }
  }

  Future<Map<String, String?>> getUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      "userName": prefs.getString("userName"),
      "picture": prefs.getString("picture"),
      "token": prefs.getString("token"),
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

  // Function to crop image
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
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop Image'),
      ],
    );

    return croppedFile != null ? File(croppedFile.path) : null;
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Location permission denied.')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permissions are permanently denied.')),
      );
      return;
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      latitudeController.text = position.latitude.toString();
      longitudeController.text = position.longitude.toString();
    });
  }

  // Function to upload image and data
  Future<void> _uploadData() async {
    try {
      // First validate all required fields
      if (_image == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Please select an image')));
        return;
      }

      // Check all required fields are filled
      final requiredControllers = {
        'Category ID': categoryIdController,
        'Tower Structure ID': towerStructureIdController,
        'Tag No': tageNoController,
        'Chemical': chemicalController,
        'Rod': rodController,
        'Earth Wire': earthWireController,
        'Earthing After': earthingAfterController,
      };

      final missingFields =
          requiredControllers.entries
              .where((entry) => entry.value.text.isEmpty)
              .map((entry) => entry.key)
              .toList();

      if (missingFields.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Missing required fields: ${missingFields.join(', ')}',
            ),
          ),
        );
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(BaseApi.baseURL + EndPoints.earthingDetail),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add all fields - EXACTLY matching Laravel expectations
      request.fields.addAll({
        'feeder_id': feederId, // From Get.arguments
        'category_id': categoryIdController.text,
        'tower_structure_id': towerStructureIdController.text,
        'latitude': latitudeController.text,
        'longitude': longitudeController.text,
        'tage_no': tageNoController.text, // Note the spelling matches Laravel
        'chemical': chemicalController.text,
        'rod': rodController.text,
        'earth_wire': earthWireController.text,
        'earthing_after': earthingAfterController.text,
        // Optional fields
        'location': locationController.text,
        'earthing_before': earthingBeforeController.text,
      });

      // Add image
      request.files.add(
        await http.MultipartFile.fromPath('image', _image!.path),
      );

      // Debug print
      print('Sending fields: ${request.fields}');

      var response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('Response status: ${response.statusCode}');
      print('Response body: $responseBody');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload successful!')));
        // Clear fields...
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed! Error: $responseBody')),
        );
      }
    } catch (e) {
      print('Exception during upload: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _loadUserData() async {
    final userData = await getUserData();
    setState(() {
      userName = userData["userName"] ?? "Guest";
      pictureUrl = userData["picture"] ?? "https://via.placeholder.com/50";
      token = userData["token"];
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Get feeder data from arguments
    final Map<String, dynamic> feederData = Get.arguments;
    feederName = feederData['name'];
    feederId = feederData['id'].toString();
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderSide: const BorderSide(width: 2.0, style: BorderStyle.solid),
      borderRadius: BorderRadius.circular(5),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: feederName,
        pictureUrl: pictureUrl,
        onLogout: _logout,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Display feeder ID (read-only)
            TextFormField(
              initialValue: feederName,
              decoration: InputDecoration(
                labelText: 'Feeder Name',
                border: border,
                enabledBorder: border,
                focusedBorder: border,
              ),
              readOnly: true,
            ),
            SizedBox(height: 10),

            // Location fields
            TextFormField(
              controller: latitudeController,
              decoration: InputDecoration(labelText: 'Latitude'),
              readOnly: true,
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: longitudeController,
              decoration: InputDecoration(labelText: 'Longitude'),
              readOnly: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _getCurrentLocation,
              child: Text('Get GPS Coordinates'),
            ),

            // Other input fields
            SizedBox(height: 10),
            TextFormField(
              controller: subDivisionIdController,
              decoration: InputDecoration(labelText: 'Sub Division ID'),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: categoryIdController,
              decoration: InputDecoration(labelText: 'Category ID'),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: towerStructureIdController,
              decoration: InputDecoration(labelText: 'Tower Structure ID'),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: locationController,
              decoration: InputDecoration(labelText: 'Location'),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: tageNoController,
              decoration: InputDecoration(labelText: 'Tag No'),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: chemicalController,
              decoration: InputDecoration(labelText: 'Chemical'),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: rodController,
              decoration: InputDecoration(labelText: 'Rod'),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: earthWireController,
              decoration: InputDecoration(labelText: 'Earth Wire'),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: earthingBeforeController,
              decoration: InputDecoration(labelText: 'Earthing Before'),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: earthingAfterController,
              decoration: InputDecoration(labelText: 'Earthing After'),
            ),

            // Image section
            SizedBox(height: 20),
            _image != null
                ? Image.file(_image!, height: 100)
                : Text('No Image Selected'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.camera),
                  child: Text('Camera'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  child: Text('Gallery'),
                ),
              ],
            ),

            // Upload button
            SizedBox(height: 20),
            ElevatedButton(onPressed: _uploadData, child: Text('Upload Data')),
          ],
        ),
      ),
    );
  }
}
