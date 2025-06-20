import 'package:flutter/material.dart';
import 'package:base_application/utils/routes/routes_names.dart';
import 'package:base_application/view/home_screen.dart';
import 'package:base_application/view/login_screen.dart';
import 'package:base_application/view/signup_screen.dart';
import 'package:base_application/view/splash_screen.dart';

class Routes {
  static Route<dynamic> generateRoutes(RouteSettings settings) {
    switch (settings.name) {
      case (RouteNames.home):
        return MaterialPageRoute(
            builder: (BuildContext context) => const HomeScreen());
      case (RouteNames.login):
        return MaterialPageRoute(
            builder: (BuildContext context) => const LoginScreen());
      case (RouteNames.signupScreen):
        return MaterialPageRoute(
            builder: (BuildContext context) => const SignUpScreen());
      case (RouteNames.splashScreen):
        return MaterialPageRoute(
            builder: (BuildContext context) => const SplashScreen());
      
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text("No route is configured"),
            ),
          ),
        );
    }
  }
}
