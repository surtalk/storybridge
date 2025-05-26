import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:storybridge_app/features/auth/controller/auth_service.dart';
import 'package:storybridge_app/features/auth/controller/login_page.dart';
import 'package:storybridge_app/features/auth/screens/home_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ MUST call this BEFORE runApp
  if (kIsWeb) {
    await AuthService().handleRedirectLogin(); // will save user if returned
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StoryBridge',
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = snapshot.data;
          if (user == null) return LoginScreen();
          return HomeScreen();
        },
      ),
    );
  }
}
