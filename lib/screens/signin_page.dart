import 'dart:io';

import 'package:chat_application/screens/login_page.dart';
import 'package:chat_application/screens/user_list_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chat_application/services/firebase_provider.dart';
import 'package:provider/provider.dart';
import '../elements/custom_button.dart';
import '../textfield.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class SigninPage extends StatefulWidget {
  static const String page = "signin_page";

  const SigninPage({super.key});

  @override
  State<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String url = "";
  Uint8List? _pickedImageForWeb;
  XFile? _pickedImageForMobile;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();

    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        _pickedImageForWeb = await pickedFile.readAsBytes();
        setState(() {}); // Refresh UI to show the picked image
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseProvider = Provider.of<FirebaseProvider>(context);
    final isLightMode = firebaseProvider.isLightMode;

    return Scaffold(
      backgroundColor: isLightMode ? Colors.white : Colors.black87,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isLightMode ? Colors.white : Colors.grey[900],
              boxShadow: [
                BoxShadow(
                  color: isLightMode
                      ? Colors.black12
                      : Colors.grey.withOpacity(0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Center(
                    child: Text(
                      "SIGN UP",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Center(
                  //   child: GestureDetector(
                  //     onTap: () {
                  //       pickImage();
                  //     },
                  //     child: CircleAvatar(
                  //       radius: 50,
                  //       backgroundImage: _pickedImageForWeb != null
                  //           ? MemoryImage(_pickedImageForWeb!)
                  //           : null,
                  //       child: _pickedImageForWeb == null
                  //           ? const Icon(
                  //               Icons.camera_alt,
                  //               color: Colors.white,
                  //               size: 40,
                  //             )
                  //           : null,
                  //     ),
                  //   ),
                  // ),
                  // const SizedBox(height: 20),
                  CustomTextfield(
                    text: "Name",
                    icon: Icons.person,
                    controller: nameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your name";
                      }
                      if (value.length < 2) {
                        return "Name must be at least 2 characters long";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  CustomTextfield(
                    text: "Email Address",
                    icon: Icons.email,
                    controller: emailController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your email";
                      }
                      final emailRegex = RegExp(
                          r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$');
                      if (!emailRegex.hasMatch(value)) {
                        return "Please enter a valid email address";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  CustomTextfield(
                    text: "Password",
                    icon: Icons.lock,
                    controller: passwordController,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your password";
                      }
                      if (value.length < 6) {
                        return "Password must be at least 6 characters long";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  CustomTextfield(
                    text: "Confirm Password",
                    icon: Icons.lock,
                    controller: confirmPasswordController,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please confirm your password";
                      }
                      if (value != passwordController.text) {
                        return "Passwords do not match";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  CustomButton(
                    loading: isLoading,
                    buttonText: 'Sign Up',
                    color: Colors.green,
                    onTap: () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() => isLoading = true); // show spinner

                        // Wait for sign-up result
                        bool isSignUpSuccessful = await firebaseProvider.signUp(
                          emailController.text.trim(),
                          passwordController.text.trim(),
                          context,
                          nameController.text.trim(),
                        );

                        setState(() => isLoading = false); // hide spinner

                        if (isSignUpSuccessful) {
                          // Navigate to next page
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => UserListPage()),
                          );

                          // Clear fields (optional)
                          emailController.clear();
                          passwordController.clear();
                          nameController.clear();
                          confirmPasswordController.clear();
                        } else {
                          // Show error dialog if sign-up fails
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Sign-up Failed'),
                              content: Text(
                                  'Please check your details and try again.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    },
                  ),

                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account?",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, LoginPage.page);
                        },
                        child: Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
