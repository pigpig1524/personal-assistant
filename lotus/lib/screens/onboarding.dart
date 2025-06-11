import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lotus/constants.dart';
import 'package:lotus/screens/chat_screen.dart';
import 'package:lotus/screens/login_screen.dart';
import 'package:lotus/screens/calendar_screen.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

final logger = Logger();

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
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
        backgroundColor: isTransparent ? Colors.transparent : white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isTransparent ? const BorderSide(color: Colors.black) : BorderSide.none,
        ),
        minimumSize: const Size(364, 48),
      ),
      child: child,
    );
  }
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _buttonSpacing = 16.0;
  static const _imageHeight = 184.0;
  static const _imageWidth = 163.0;

  Future<void> _signOut() async {
    try {
      // Sign out from Firebase and Google
      await FirebaseAuth.instance.signOut();
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }

      // Clear access token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      logger.e('Error signing out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đăng xuất: $e')),
        );
      }
    }
  }

  Future<void> _navigateToCalendar() async {
    try {
      // Load access token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');

      if (accessToken != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CalendarScreen(accessToken: accessToken),
          ),
        );
      } else {
        // Try to refresh token if not available
        final googleSignIn = GoogleSignIn(
          scopes: ['email', 'https://www.googleapis.com/auth/calendar.events'],
        );
        final googleUser = await googleSignIn.signInSilently();
        if (googleUser == null) {
          throw Exception('Không thể đăng nhập lại tự động');
        }

        final googleAuth = await googleUser.authentication;
        final newToken = googleAuth.accessToken;

        if (newToken != null && mounted) {
          await prefs.setString('access_token', newToken);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CalendarScreen(accessToken: newToken),
            ),
          );
        } else {
          throw Exception('Không thể lấy Access Token');
        }
      }
    } catch (e) {
      logger.e('Lỗi khi truy cập Calendar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'User';

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: auth1gradient, // Use gradient for consistency with LoginScreen
            ),
          ),
          Align(
            alignment: const FractionalOffset(0.5, 0.6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/robot2.png',
                  height: _imageHeight,
                  width: _imageWidth,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 30),
                Text(
                  'Welcome, $displayName!',
                  style: onboardingheading,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Your AI companion for everyday tasks',
                  style: onboardingbody,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                CustomButton(
                  onPressed: _signOut,
                  child: const Text('Sign Out', style: onboardingheading),
                ),
                const SizedBox(height: _buttonSpacing),
                CustomButton(
                  onPressed: _navigateToCalendar,
                  child: const Text('View Calendar', style: onboardingheading),
                ),
                const SizedBox(height: _buttonSpacing),
                CustomButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatScreen()),
                    );
                  },
                  child: const Text('Start Chat', style: onboardingheading),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}