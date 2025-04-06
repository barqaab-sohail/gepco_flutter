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
import 'dart:convert'; // Add this line with other imports

// Add these model classes
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
  String feederName = '';
  String feederId = '';

  // For dropdowns
  List<Category> categories = [];
  List<TowerStructure> towerStructures = [];
  int? selectedCategoryId;
  int? selectedTowerStructureId;
  bool isLoading = false;

  // Controllers for other fields
  TextEditingController latitudeController = TextEditingController();
  TextEditingController longitudeController = TextEditingController();
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

  // Modify the _uploadData method to use the selected dropdown values
  Future<void> _uploadData() async {
    try {
      // First validate all required fields
      if (_image == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Please select an image')));
        return;
      }

      // Check dropdown selections
      if (selectedCategoryId == null || selectedTowerStructureId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select both category and structure')),
        );
        return;
      }

      // Check other required fields are filled
      final requiredControllers = {
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

      // Add all fields - using dropdown selected values
      request.fields.addAll({
        'feeder_id': feederId,
        'category_id': selectedCategoryId.toString(),
        'tower_structure_id': selectedTowerStructureId.toString(),
        'latitude': latitudeController.text,
        'longitude': longitudeController.text,
        'tage_no': tageNoController.text,
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
        _resetForm();
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

  void _resetForm() {
    setState(() {
      // Reset image
      _image = null;

      // Reset dropdowns
      selectedCategoryId = null;
      selectedTowerStructureId = null;

      // Reset all text controllers
      latitudeController.clear();
      longitudeController.clear();
      locationController.clear();
      tageNoController.clear();
      chemicalController.clear();
      rodController.clear();
      earthWireController.clear();
      earthingBeforeController.clear();
      earthingAfterController.clear();
    });
  }

  @override
  void initState() {
    super.initState();

    // Initialize feeder data
    final Map<String, dynamic> feederData = Get.arguments;
    setState(() {
      feederName = feederData['name'] ?? '';
      feederId = feederData['id']?.toString() ?? '';
    });

    // Load user data and dropdowns
    _loadUserData().then((_) {
      _loadDropdownData();
    });
  }

  Future<void> _loadDropdownData() async {
    if (token == null) {
      print('Token is null, cannot load dropdown data');
      return;
    }
    setState(() {
      isLoading = true;
    });

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
        setState(() {
          categories =
              (data['categories'] as List)
                  .map((item) => Category.fromJson(item))
                  .toList();
          towerStructures =
              (data['towerStructures'] as List)
                  .map((item) => TowerStructure.fromJson(item))
                  .toList();
        });
      } else {
        print(
          'Fetching dropdown data from: $uri and $token and ${response.statusCode}',
        ); // Debug print
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load dropdown data')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading dropdown data: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  InputDecoration _buildInputDecoration(
    String labelText, {
    bool isRequired = true,
  }) {
    return InputDecoration(
      labelText: isRequired ? '$labelText *' : labelText,
      labelStyle: TextStyle(
        color: isRequired ? Colors.red : null, // Make asterisk red
      ),
      border: OutlineInputBorder(
        borderSide: BorderSide(width: 2.0, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(5),
      ),
    );
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
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
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
                      decoration: _buildInputDecoration('Latitude'),
                      readOnly: true,
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: longitudeController,
                      decoration: _buildInputDecoration('Longitude'),
                      readOnly: true,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _getCurrentLocation,
                      child: Text('Get GPS Coordinates'),
                    ),

                    // Dropdown for Category
                    SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      decoration: _buildInputDecoration('Category'),
                      value: selectedCategoryId,
                      items:
                          categories.map((Category category) {
                            return DropdownMenuItem<int>(
                              value: category.id,
                              child: Text(category.name),
                            );
                          }).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          selectedCategoryId = newValue;
                        });
                      },
                      validator:
                          (value) =>
                              value == null ? 'Please select a category' : null,
                    ),

                    // Dropdown for Tower Structure
                    SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      decoration: _buildInputDecoration('Tower Structure'),
                      value: selectedTowerStructureId,
                      items:
                          towerStructures.map((TowerStructure structure) {
                            return DropdownMenuItem<int>(
                              value: structure.id,
                              child: Text(structure.name),
                            );
                          }).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          selectedTowerStructureId = newValue;
                        });
                      },
                      validator:
                          (value) =>
                              value == null
                                  ? 'Please select a structure'
                                  : null,
                    ),

                    // Other input fields
                    SizedBox(height: 10),
                    TextFormField(
                      controller: locationController,
                      decoration: _buildInputDecoration(
                        'Location',
                        isRequired: false,
                      ),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: tageNoController,
                      decoration: _buildInputDecoration('Tag No'),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: chemicalController,
                      decoration: _buildInputDecoration('Chemical'),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: rodController,
                      decoration: _buildInputDecoration('Rod'),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: earthWireController,
                      decoration: _buildInputDecoration('Earth Wire'),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: earthingBeforeController,
                      decoration: _buildInputDecoration('Earth Before'),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: earthingAfterController,
                      decoration: _buildInputDecoration('Earth After'),
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
                    ElevatedButton(
                      onPressed: _uploadData,
                      child: Text('Upload Data'),
                    ),
                  ],
                ),
              ),
    );
  }
}
