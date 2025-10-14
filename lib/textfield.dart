import 'package:flutter/material.dart';

class CustomTextfield extends StatefulWidget {
  final String text;
  final IconData? icon;
  final TextEditingController controller;
  final bool isPassword;
  final String? Function(String?)? validator;

  CustomTextfield({
    Key? key,
    required this.text,
    this.icon,
    required this.controller,
    this.isPassword = false,
    this.validator,
  }) : super(key: key);

  @override
  State<CustomTextfield> createState() => _CustomTextfieldState();
}

class _CustomTextfieldState extends State<CustomTextfield> {
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _isPasswordVisible = !widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: widget.isPassword && !_isPasswordVisible,
      controller: widget.controller,
      style: const TextStyle(
        color: Colors.green,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w300,
      ),
      validator: widget.validator,
      decoration: InputDecoration(
        suffixIcon: widget.isPassword
            ? GestureDetector(
                onTap: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
                child: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.green,
                ),
              )
            : null,
        prefixIcon:
            widget.icon != null ? Icon(widget.icon, color: Colors.green) : null,
        hintText: widget.text,
        hintStyle: const TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.w300,
          fontFamily: 'Roboto',
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.green),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.green),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.green, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2.0),
        ),
      ),
    );
  }
}
