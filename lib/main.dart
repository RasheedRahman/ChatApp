import 'package:chat_application/firebase_options.dart';
import 'package:chat_application/screens/chat_page.dart';
import 'package:chat_application/screens/login_page.dart';
import 'package:chat_application/screens/signin_page.dart';
import 'package:chat_application/screens/user_list_page.dart';
import 'package:chat_application/services/firebase_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FirebaseProvider>(
            create: (_) => FirebaseProvider()),
        ChangeNotifierProvider<MyTextProvider>(create: (_) => MyTextProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: LoginPage.page,
        routes: {
          LoginPage.page: (context) => LoginPage(),
          SigninPage.page: (context) => SigninPage(),
          UserListPage.page: (context) => UserListPage()
        },
      ),
    );
  }
}
