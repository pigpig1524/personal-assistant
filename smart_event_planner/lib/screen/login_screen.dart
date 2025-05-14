import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smart_event_planner/constants.dart';
import 'package:smart_event_planner/screen/onboarding.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    this.isTransparent = false,
    required this.onPressed,
    required this.child,
  });

  final bool isTransparent;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: child,
    );
  }
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OnboardingScreen()));
        }
      }
    });
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login success!')),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OnboardingScreen()));
      }
    } catch (e) {
      if (mounted) {
        logger.i('Error login: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: auth1gradient,
            ),
          ),
          Align(
            alignment: const FractionalOffset(0.5, 0.6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  "assets/images/robot1.png",
                  height: 184,
                  width: 163,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 30),
                const Text(
                  "Hi! I’m Name",
                  style: auth1heading,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Let’s make today a nice day!",
                  style: auth1body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                GestureDetector(
                  onTap: signInWithGoogle,
                  child: Image.asset(
                    "assets/images/btn_google_light.png",
                    height: 46,
                    width: 179,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
