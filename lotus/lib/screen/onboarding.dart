import 'package:flutter/material.dart';
import 'package:lotus/constants.dart';
import 'package:lotus/screen/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';
import 'package:lotus/screen/calendar_screen.dart';

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
      ),
      child: child,
    );
  }
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  
  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        logger.i('Error signout: $e');
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
              color: white,
            ),
          ),
          Align(
            alignment: const FractionalOffset(0.5, 0.6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  "assets/images/robot2.png",
                  height: 184,
                  width: 163,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 30),
                Text(
                  "Welcome $displayName !",
                  style: onboardingheading,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Your AI companion for everyday tasks",
                  style: onboardingbody,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 120),
                ElevatedButton(
                  onPressed: () {
                    signOut(); 
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: peri, 
                    minimumSize: Size(364, 48),  
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.0), 
                    ),
                    
                  ),
                  child: const Text("Sign Out", style: auth1body,)
                ),
                const SizedBox(height: 120),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final GoogleSignIn googleSignIn = GoogleSignIn(
                        scopes: ['email', 'https://www.googleapis.com/auth/calendar.readonly'],
                      );
                      
                      final googleUser = await googleSignIn.signIn();
                      if (googleUser == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đăng nhập Google thất bại')),
                        );
                        return;
                      }

                      final googleAuth = await googleUser.authentication;
                      final accessToken = googleAuth.accessToken;

                      if (accessToken != null && mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CalendarScreen(accessToken: accessToken),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Không thể lấy Access Token')),
                        );
                      }
                    } catch (e) {
                      logger.e("Lỗi khi đăng nhập Google: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e')),
                      );
                    }
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: peri, 
                    minimumSize: Size(364, 48),  
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.0), 
                    ),
                    
                  ),
                  child: const Text("Test", style: auth1body,)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
