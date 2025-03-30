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
  TextEditingController latitudeController = TextEditingController();
  TextEditingController longitudeController = TextEditingController();
  TextEditingController feederNameController = TextEditingController();

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

  // Function to upload image and coordinates
  Future<void> _uploadData() async {
    if (_image == null ||
        latitudeController.text.isEmpty ||
        longitudeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please get coordinates and select an image')),
      );
      return;
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse(BaseApi.baseURL + EndPoints.save),
    );

    request.fields['latitude'] = latitudeController.text;
    request.fields['longitude'] = longitudeController.text;
    request.files.add(await http.MultipartFile.fromPath('image', _image!.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload successful!')));

      setState(() {
        // Clear all fields after successful upload
        latitudeController.clear();
        longitudeController.clear();
        _image = null;
      });
    } else {
      print(Uri.parse(BaseApi.baseURL + EndPoints.save));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed!')));
    }
  }

  Future<void> _loadUserData() async {
    final userData = await getUserData();
    setState(() {
      userName = userData["userName"] ?? "Guest";
      pictureUrl =
          userData["picture"] ??
          "https://via.placeholder.com/50"; // Default image
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderSide: const BorderSide(width: 2.0, style: BorderStyle.solid),
      borderRadius: BorderRadius.circular(5),
    );
    final Map<String, dynamic> divisionData = Get.arguments;
    final String divisionName = divisionData['name']; // Extract Division Name
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: divisionName,
        pictureUrl: pictureUrl,
        onLogout: _logout,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
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
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _uploadData,
                child: Text('Upload Data'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
