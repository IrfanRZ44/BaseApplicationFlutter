// lib/main.dart

// Importing necessary packages
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test2/input_bcc.dart';

// Importing custom screens
import 'login.dart';
import 'main_screen.dart';

void main() async {
  // Ensures all Flutter bindings are initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();

  // Access shared preferences to check login status
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

  // Start the app with initial route based on login state
  runApp(MyApp(initialRoute: isLoggedIn ? '/main' : '/login'));
}

class MyApp extends StatelessWidget {
  // Initial route passed from main function
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Hides the debug banner in top right corner
      debugShowCheckedModeBanner: false,
      // Title shown in task manager or app switcher
      title: 'Flutter Login',

      // Define app theme using Material 3 and custom color
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),

      // Set the initial route (login or main screen)
      initialRoute: initialRoute,

      // Define app routes for navigation
      routes: {
        '/login': (context) => LoginPage(),   // Login screen
        '/main': (context) => MainScreen(),   // Main screen after login
        '/input_bcc': (context) => InputBCC(),   // Main screen after login
      },
    );
  }
}
