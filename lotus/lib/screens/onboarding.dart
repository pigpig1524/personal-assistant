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

class _OnboardingScreenState extends State<OnboardingScreen> {
  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi đăng xuất: $e')));
      }
    }
  }

  Future<void> _navigateToCalendar() async {
    try {
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'User';

    // Define a common button style
    final ButtonStyle commonButtonStyle = ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      backgroundColor: white,
      foregroundColor: black,
      elevation: 2,
    );

    return Scaffold(
      backgroundColor: white,
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Column for welcome text and subtitle
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, $displayName!',
                          style: onboardingheading,
                        ),
                        const SizedBox(height: 4), // small spacing
                        Text(
                          "Let's make today a nice day.",
                          style: onboardingheading.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: user?.photoURL != null
                          ? Image.network(
                              user!.photoURL!,
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              'assets/images/default_avt.png',
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 16), // spacing before divider
                const Divider(color: black, thickness: 1, height: 1),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ElevatedButton(
                    style: commonButtonStyle,
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatScreen()),
                      );
                    },
                    child: Center(
                      child: const Text('Chat', style: onboardingheading),
                    ),
                  ),
                  const SizedBox(height: 16), // spacing between buttons
                  ElevatedButton(
                    style: commonButtonStyle,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Activities feature coming soon!'),
                        ),
                      );
                    },
                    child: Center(
                      child: const Text('Activities', style: onboardingheading),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: commonButtonStyle,
                    onPressed: _navigateToCalendar,
                    child: Center(
                      child: const Text('Calendar', style: onboardingheading),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: commonButtonStyle,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Planning feature coming soon!'),
                        ),
                      );
                    },
                    child: Center(
                      child: const Text('Planning', style: onboardingheading),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: commonButtonStyle,
                    onPressed: _signOut,
                    child: Center(
                      child: const Text('Sign Out', style: onboardingheading),
                    ),
                  ),
                ],
              ),
            ),

            Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {});
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF92A3FD),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/robot_light.png',
                      fit: BoxFit.scaleDown, // scales image down to fit inside container
                      height: 60, // control max height
                      width: 60, // control max width
                      alignment: Alignment.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
