import 'package:chat_application/screens/signin_page.dart';
import 'package:chat_application/screens/user_list_page.dart';
import 'package:flutter/material.dart';
import 'package:chat_application/services/firebase_provider.dart';
import 'package:provider/provider.dart';
import '../elements/custom_button.dart';
import '../textfield.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  static const String page = "login_page";

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
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
                      "LOGIN",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
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
                      if (value.length < 8) {
                        return "Password must be at least 6 characters long";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      //Navigator.pushNamed(context, UserListPage.page);
                    },
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "Forget Password?",
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  CustomButton(
                    loading: isLoading,
                    buttonText: 'Login',
                    color: Colors.green,
                    onTap: () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() => isLoading = true);

                        bool success = await firebaseProvider.signIn(
                          emailController.text.trim(),
                          passwordController.text.trim(),
                          context,
                        );

                        setState(() => isLoading = false);

                        if (!success) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Sign-in Failed'),
                              content:
                                  Text('Please check your email and password.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }

                        emailController.clear();
                        passwordController.clear();
                      }
                    },
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, SigninPage.page);
                        },
                        child: Text(
                          "Signup",
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
