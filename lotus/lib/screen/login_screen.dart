import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lotus/constants.dart';
import 'package:lotus/screen/onboarding.dart';
import 'package:lotus/screen/calendar_screen.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
    _checkLoginStatus();
  }

  /// Read access token
  Future<void> _checkLoginStatus() async {
    final token = await _loadAccessToken();
    if (token != null) {
      logger.i("Tìm thấy token, chuyển tới CalendarScreen");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CalendarScreen(accessToken: token),
          ),
        );
      }
    } else {
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user != null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => OnboardingScreen()),
          );
        }
      });
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'https://www.googleapis.com/auth/calendar',
        ],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      final accessToken = googleAuth.accessToken;
      if (accessToken == null) throw Exception("Access token is null");

      logger.i("Access Token: $accessToken");

      // Save token
      await _saveAccessToken(accessToken);

      // API Calendar
      final response = await http.get(
        Uri.parse(
            'https://www.googleapis.com/calendar/v3/calendars/primary/events'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        logger.i("Calendar events: ${response.body}");
      } else {
        logger.w("Calendar error: ${response.statusCode} - ${response.body}");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login success!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CalendarScreen(accessToken: accessToken),
          ),
        );
      }
    } catch (e) {
      logger.e('Lỗi đăng nhập: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  Future<String?> _loadAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
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
