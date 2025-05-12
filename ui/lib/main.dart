import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/signin_google.dart';
import 'pages/home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Assistant',
      debugShowCheckedModeBanner: false,
      initialRoute: '/home',
      routes: {
        // '/signin': (context) => const SignInWithGooglePage(),
        // '/home': (context) => const HomePage(),
      },
    );}
}