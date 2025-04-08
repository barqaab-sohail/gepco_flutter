import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/custom_app_bar.dart';
import 'package:gepco_front_flutter/controllers/earthing_table_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EarthingTableView extends StatelessWidget {
  final controller = Get.put(EarthingTableController());

  EarthingTableView({super.key});

  InputDecoration _buildInputDecoration(
    String label, {
    bool isRequired = true,
  }) {
    return InputDecoration(
      labelText: isRequired ? '$label *' : label,
      labelStyle: TextStyle(color: isRequired ? Colors.red : null),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        appBar: CustomAppBar(
          title: controller.feederName,
          pictureUrl: controller.pictureUrl,
          onLogout: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.clear();
            Get.offAllNamed('/login');
          },
        ),
        body:
            controller.isLoading.value
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: controller.feederName,
                        decoration: _buildInputDecoration('Feeder Name'),
                        readOnly: true,
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: controller.latitudeController,
                        decoration: _buildInputDecoration('Latitude'),
                        readOnly: true,
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: controller.longitudeController,
                        decoration: _buildInputDecoration('Longitude'),
                        readOnly: true,
                      ),
                      ElevatedButton(
                        onPressed: controller.getCurrentLocation,
                        child: Text('Get GPS Coordinates'),
                      ),
                      SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        value: controller.selectedCategoryId.value,
                        items:
                            controller.categories
                                .map(
                                  (cat) => DropdownMenuItem(
                                    value: cat.id,
                                    child: Text(cat.name),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (val) => controller.selectedCategoryId.value = val,
                        decoration: _buildInputDecoration('Category'),
                      ),
                      SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        value: controller.selectedTowerStructureId.value,
                        items:
                            controller.towerStructures
                                .map(
                                  (ts) => DropdownMenuItem(
                                    value: ts.id,
                                    child: Text(ts.name),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (val) =>
                                controller.selectedTowerStructureId.value = val,
                        decoration: _buildInputDecoration('Tower Structure'),
                      ),
                      ...[
                        {
                          'label': 'Location',
                          'controller': controller.locationController,
                          'required': false,
                        },
                        {
                          'label': 'Tag No',
                          'controller': controller.tageNoController,
                        },
                        {
                          'label': 'Chemical',
                          'controller': controller.chemicalController,
                          'keyboardType': TextInputType.number,
                        },
                        {
                          'label': 'Rod',
                          'controller': controller.rodController,
                          'keyboardType': TextInputType.number,
                        },
                        {
                          'label': 'Earth Wire',
                          'controller': controller.earthWireController,
                          'keyboardType': TextInputType.number,
                        },
                        {
                          'label': 'Earthing Before',
                          'controller': controller.earthingBeforeController,
                          'required': false,
                          'keyboardType': TextInputType.number,
                        },
                        {
                          'label': 'Earthing After',
                          'controller': controller.earthingAfterController,
                          'keyboardType': TextInputType.number,
                        },
                      ].map(
                        (field) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: TextFormField(
                            controller:
                                field['controller'] as TextEditingController,
                            decoration: _buildInputDecoration(
                              field['label'] as String,
                              isRequired: field['required'] as bool? ?? true,
                            ),
                            keyboardType:
                                field['keyboardType'] as TextInputType?,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Obx(
                        () =>
                            controller.image.value != null
                                ? Image.file(
                                  controller.image.value!,
                                  height: 100,
                                )
                                : Text('No Image Selected'),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed:
                                () => controller.pickImage(ImageSource.camera),
                            child: Text('Camera'),
                          ),
                          SizedBox(width: 10),
                          ElevatedButton(
                            onPressed:
                                () => controller.pickImage(ImageSource.gallery),
                            child: Text('Gallery'),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: controller.uploadData,
                        child: Text('Upload Data'),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
