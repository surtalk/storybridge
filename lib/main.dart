import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:storybridge_app/features/auth/controller/login_page.dart';
import 'package:storybridge_app/features/auth/screens/home_screen.dart';
import 'package:storybridge_app/features/auth/screens/waiting_approval_screen.dart';
import 'package:storybridge_app/features/auth/services/user_service.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
// We'll create this to check approval status

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StoryBridge',
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          if (snapshot.hasData) {
            return FutureBuilder<bool>(
              future: UserService().isUserApproved(),
              builder: (context, approvalSnapshot) {
                if (approvalSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (approvalSnapshot.data == true) {
                  return HomeScreen(); // ✅ Approved user
                } else {
                  return WaitingApprovalScreen(); // ⏳ Guest user
                }
              },
            );
          }

          return LoginScreen(); // 🔐 Not signed in
        },
      ),
    );
  }
}
