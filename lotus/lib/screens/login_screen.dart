import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lotus/constants.dart';
import 'package:lotus/screens/home_screen.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: child,
    );
  }
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final accessToken = await _refreshAccessToken();

      if (accessToken != null) {
        await _updateAccessTokenToFirestore(user, accessToken);
        logger.i("Access token làm mới thành công, chuyển tới HomeScreen");
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen()),
          );
        }
      } else {
        logger.w("Không thể làm mới token, chuyển tới HomeScreen");
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen()),
          );
        }
      }
    } else {
      logger.i("Chưa có user đăng nhập, giữ nguyên màn hình Login");
    }
  }

  Future<void> _updateAccessTokenToFirestore(
    User user,
    String accessToken,
  ) async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'accessToken': accessToken,
      'email': user.email,
      'displayName': user.displayName,
      'lastSignIn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> signInWithGoogle() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'https://www.googleapis.com/auth/userinfo.profile',
          'https://www.googleapis.com/auth/gmail.readonly',
          'https://www.googleapis.com/auth/gmail.compose',
          'https://www.googleapis.com/auth/gmail.modify',
        ],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        logger.w("Google Sign-In bị hủy");
        setState(() {
          _isLoading = false; // Stop loading if cancelled
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      final accessToken = googleAuth.accessToken;
      if (accessToken == null) throw Exception("Access token is null");

      logger.i("Access Token length: ${accessToken.length}");

      await _saveAccessToken(accessToken);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _updateAccessTokenToFirestore(user, accessToken);
      }

      final response = await http.get(
        Uri.parse(
          'https://www.googleapis.com/calendar/v3/calendars/primary/events',
        ),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        logger.i("Calendar events: ${response.body}");
      } else {
        logger.w("Calendar error: ${response.statusCode} - ${response.body}");
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đăng nhập thành công!')));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      }
    } catch (e) {
      logger.e('Lỗi đăng nhập: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Always stop loading at the end
        });
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

  Future<String?> _refreshAccessToken() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email', 'https://www.googleapis.com/auth/calendar.events'],
    );

    GoogleSignInAccount? googleUser = googleSignIn.currentUser;
    googleUser ??= await googleSignIn.signInSilently();

    if (googleUser == null) {
      logger.w("Không thể đăng nhập lại silently");
      return null;
    }

    final googleAuth = await googleUser.authentication;
    final newAccessToken = googleAuth.accessToken;

    if (newAccessToken != null) {
      await _saveAccessToken(newAccessToken);
      logger.i("Access token đã được làm mới");
      return newAccessToken;
    } else {
      logger.w("Lỗi khi làm mới access token");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: auth1gradient)),
          Align(
            alignment: const FractionalOffset(0.5, 0.6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  "assets/images/robot_light.png",
                  height: 184,
                  width: 163,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 30),
                const Text("Hi! I’m Lotus", style: auth1heading),
                const SizedBox(height: 20),
                const Text(
                  "Let’s make today a nice day!",
                  style: auth1body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                GestureDetector(
                  onTap: _isLoading ? null : signInWithGoogle,
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
          if (_isLoading)
            Container(
              color: white,
              child: const Center(
                child: CircularProgressIndicator(color: black),
              ),
            ),
        ],
      ),
    );
  }
}
