import 'package:flutter/material.dart';

class CustomFormField extends StatelessWidget {
  final bool obscureText;
  final String hintText;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final Function(String?) onSaved;

  const CustomFormField({
    super.key,
    required this.hintText,
    required this.validator,
    required this.onSaved,
    required this.controller,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: TextFormField(
        obscureText: obscureText,
        controller: controller,
        decoration: InputDecoration(hintText: hintText),
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }
}
