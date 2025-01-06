import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';

void main() async {
  // Ensures that Flutter bindings are initialized before running the app.
  WidgetsFlutterBinding.ensureInitialized();

  // Initializes Firebase with platform-specific options.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Runs the main application.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Sets the initial screen of the app to the authentication screen.
      home: AuthScreen(),
    );
  }
}
