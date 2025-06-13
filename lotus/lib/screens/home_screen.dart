import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';
import 'package:lotus/screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lotus/constants.dart';
import 'package:lotus/screens/chat_screen.dart';
import 'package:lotus/screens/email_screen.dart';
import 'package:lotus/screens/calendar_screen.dart';
import 'package:lotus/screens/login_screen.dart';

final logger = Logger();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
        Navigator.push(
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
          Navigator.push(
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

  Future<void> _navigateToEmail() async {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EmailScreen()),
      );
    } catch (e) {
      logger.e('Error when access to email functions: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _navigateToProfile() async {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfileScreen()),
      );
    } catch (e) {
      logger.e('Error when access to email functions: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'User';

    return Scaffold(
      backgroundColor: white,
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ListView(
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
                          style: homeHeadingTxtStyle1,
                        ),
                        const SizedBox(height: 4), // small spacing
                        Text(
                          "Let's make today a nice day.",
                          style: homeHeadingTxtStyle2.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),

                    Material(
                      color: white,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          _navigateToProfile();
                        },
                        child: Container(
                          padding: EdgeInsets.all(12.0),
                          child: user?.photoURL != null
                              ? Image.network(
                                  user!.photoURL!,
                                  height: 70,
                                  width: 70,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  'assets/images/default_avt.png',
                                  height: 70,
                                  width: 70,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16), // spacing before divider
                const Divider(color: black, thickness: 1, height: 1),
              ],
            ),

            const SizedBox(height: 30),

            Material(
              color: white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: homeGrayoutBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Chat', style: homeFunctionHeaderTxtStyle),
                      const SizedBox(height: 8),
                      const Text(
                        'Ready to process your request and answer your question!',
                        style: homeFunctionBodyTxtStyle1,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: const Text(
                          'View more',
                          style: homeFunctionBodyTxtStyle2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Material(
              color: white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  _navigateToEmail();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: homeGrayoutBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Email ', style: homeFunctionHeaderTxtStyle),
                      const SizedBox(height: 8),
                      const Text(
                        'You can manage your emails here!',
                        style: homeFunctionBodyTxtStyle1,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: const Text(
                          'View more',
                          style: homeFunctionBodyTxtStyle2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Material(
              color: white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  _navigateToCalendar();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: homeGrayoutBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Calendar', style: homeFunctionHeaderTxtStyle),
                      const SizedBox(height: 8),
                      const Text(
                        'Access to your calendar and upcoming activities here!',
                        style: homeFunctionBodyTxtStyle1,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: const Text(
                          'View more',
                          style: homeFunctionBodyTxtStyle2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10), 

            Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _signOut,
                child: Container(
                  padding: EdgeInsets.all(6.0),
                  child: Image.asset(
                    'assets/icons/logout.png',
                    height: 60,
                    width: 60,
                    fit: BoxFit.contain,
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
