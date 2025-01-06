import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart'; // Import for TextInputFormatter
import 'main_app.dart'; // Redirects to your main application screen

// This is the main authentication screen widget.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() {
    return _AuthScreenState();
  }
}

// This is the state class for the AuthScreen widget, handling the logic and UI.
class _AuthScreenState extends State<AuthScreen> {
  // Controllers for managing the text input fields
  final _emailController = TextEditingController(); // Email input controller
  final _passwordController =
      TextEditingController(); // Password input controller
  final _userNameController =
      TextEditingController(); // Username input controller
  final _phoneController =
      TextEditingController(); // Phone number input controller

  // State variable to toggle between login and signup screens
  bool _isLogin = true;

  // TextInputFormatter to allow only digits in the phone number input
  final TextInputFormatter _phoneFormatter =
      FilteringTextInputFormatter.digitsOnly; // Allows only numbers

  // Method to handle form submission for login or signup
  Future<void> _submit() async {
    try {
      UserCredential userCredential;

      if (_isLogin) {
        // 📌 LOGIN: Authenticate the user with email and password
        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        // 📌 SIGNUP: Create a new user with email and password
        userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        // After user registration, save additional user data to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': _emailController.text, // Save the email
          'userName': _userNameController.text, // Save the username
          'profilePhotoUrl': '', // Default empty profile photo
          'createdAt': Timestamp.now(), // Save the registration timestamp
          'userId': userCredential.user!.uid, // Save the user ID
          'deviceToken': '', // Placeholder for device token
          'phone': _phoneController.text, // Save the phone number
        });
      }

      // 📌 Fetch and save the user's device token after successful login/signup
      await _saveDeviceToken(userCredential.user!.uid);

      // 📌 Navigate to the main application screen after successful authentication
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyApp()), // Main application
      );
    } catch (e) {
      // Display error messages to the user using a snackbar
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  // 📌 Save the user's device token to Firestore
  Future<void> _saveDeviceToken(String userId) async {
    try {
      String? token =
          await FirebaseMessaging.instance.getToken(); // Fetch the device token
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'deviceToken': token}); // Save the token in Firestore
      }
    } catch (e) {
      // Log an error if the token could not be saved
      print("Error saving device token: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Main UI of the authentication screen
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(16.0), // Add padding to the container
        decoration: BoxDecoration(
          color: Color(0xFFFFF5EE), // Background color
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center the content
          children: <Widget>[
            // App icon widget
            Center(
              child: Image.asset(
                'assets/images/icon.png', // Path to your app icon image
                width: 200, // Icon width
                height: 200, // Icon height
              ),
            ),
            SizedBox(height: 30), // Space between the icon and input fields

            // Username input field (visible only during signup)
            if (!_isLogin)
              TextField(
                controller: _userNameController,
                decoration: InputDecoration(labelText: 'Kullanıcı Adı'),
              ),

            // Email input field
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'E-posta'),
              keyboardType:
                  TextInputType.emailAddress, // Set keyboard type to email
            ),

            // Password input field
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Şifre'),
              obscureText: true, // Hide the text for password security
            ),

            // Phone input field (visible only during signup)
            if (!_isLogin)
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Telefon Numarası', // Label for the phone field
                  hintText: '(5xx)xxxxxxx', // Placeholder hint text
                ),
                keyboardType: TextInputType.phone, // Set keyboard type to phone
                inputFormatters: [
                  _phoneFormatter, // Allow only digits
                  LengthLimitingTextInputFormatter(
                      10), // Limit input length to 10
                ],
              ),

            SizedBox(height: 20), // Space before the buttons

            // Submit button
            ElevatedButton(
              onPressed: _submit, // Call the _submit method on press
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE3963E), // Button color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Rounded corners
                ),
                padding: EdgeInsets.symmetric(vertical: 14), // Button padding
                minimumSize: Size(double.infinity, 50), // Full-width button
              ),
              child: Text(
                _isLogin
                    ? 'Giriş Yap'
                    : 'Kayıt Ol', // Change text based on state
                style: TextStyle(
                  fontSize: 16, // Font size
                  fontWeight: FontWeight.bold, // Bold text
                  color: Colors.white, // Text color
                ),
              ),
            ),

            // Toggle between login and signup
            TextButton(
              onPressed: () {
                setState(() {
                  _isLogin = !_isLogin; // Toggle the _isLogin state
                });
              },
              child: Text(_isLogin
                  ? 'Hesabınız yok mu? Kayıt ol' // Signup prompt
                  : 'Zaten hesabınız var mı? Giriş yap'), // Login prompt
            ),
          ],
        ),
      ),
    );
  }
}
